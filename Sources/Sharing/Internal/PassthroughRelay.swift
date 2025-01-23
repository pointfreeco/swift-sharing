#if canImport(Combine)
  import Combine
  import Foundation

  final class PassthroughRelay<Output>: Subject {
    typealias Failure = Never

    private let lock: os_unfair_lock_t
    private var _upstreams: [any Combine.Subscription] = []
    private var _downstreams = ContiguousArray<Subscription>()

    init() {
      self.lock = os_unfair_lock_t.allocate(capacity: 1)
      self.lock.initialize(to: os_unfair_lock())
    }

    deinit {
      for subscription in _upstreams {
        subscription.cancel()
      }
      lock.deinitialize(count: 1)
      lock.deallocate()
    }

    func receive(subscriber: some Subscriber<Output, Never>) {
      let subscription = Subscription(upstream: self, downstream: subscriber)
      lock.withLock { _downstreams.append(subscription) }
      subscriber.receive(subscription: subscription)
    }

    func send(_ value: Output) {
      for subscription in lock.withLock({ _downstreams }) {
        subscription.receive(value)
      }
    }

    func send(completion: Subscribers.Completion<Never>) {
      let subscriptions = lock.withLock {
        let subscriptions = _downstreams
        _downstreams.removeAll()
        return subscriptions
      }
      for subscription in subscriptions {
        subscription.receive(completion: completion)
      }
    }

    func send(subscription: any Combine.Subscription) {
      lock.withLock { _upstreams.append(subscription) }
      subscription.request(.unlimited)
    }

    private func remove(_ subscription: Subscription) {
      lock.withLock {
        guard let index = _downstreams.firstIndex(of: subscription)
        else { return }
        _downstreams.remove(at: index)
      }
    }

    fileprivate final class Subscription: Combine.Subscription, Equatable {
      private var demand = Subscribers.Demand.none
      private var downstream: (any Subscriber<Output, Never>)?
      private let lock: os_unfair_lock_t
      private var upstream: PassthroughRelay?

      init(upstream: PassthroughRelay, downstream: any Subscriber<Output, Never>) {
        self.upstream = upstream
        self.downstream = downstream
        self.lock = os_unfair_lock_t.allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
      }

      deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
      }

      func cancel() {
        lock.withLock {
          downstream = nil
          upstream?.remove(self)
          upstream = nil
        }
      }

      func receive(_ value: Output) {
        lock.lock()

        guard let downstream else {
          lock.unlock()
          return
        }

        switch demand {
        case .unlimited:
          lock.unlock()
          // NB: Adding to unlimited demand has no effect and can be ignored.
          _ = downstream.receive(value)

        case .none:
          lock.unlock()

        default:
          demand -= 1
          lock.unlock()
          let moreDemand = downstream.receive(value)
          lock.withLock { demand += moreDemand }
        }
      }

      func receive(completion: Subscribers.Completion<Never>) {
        lock.withLock {
          downstream?.receive(completion: completion)
          downstream = nil
          upstream = nil
        }
      }

      func request(_ demand: Subscribers.Demand) {
        precondition(demand > 0, "Demand must be greater than zero")
        lock.lock()
        defer { lock.unlock() }
        guard case .some = downstream else { return }
        self.demand += demand
        guard let upstream else { return }
        let subscriptions = upstream.lock.withLock { upstream._upstreams }
        for subscription in subscriptions {
          subscription.request(.unlimited)
        }
      }

      static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        lhs === rhs
      }
    }
  }

  extension os_unfair_lock_t {
    fileprivate func withLock<R>(_ body: () throws -> R) rethrows -> R {
      lock()
      defer { unlock() }
      return try body()
    }

    fileprivate func lock() {
      os_unfair_lock_lock(self)
    }

    fileprivate func unlock() {
      os_unfair_lock_unlock(self)
    }
  }
#endif
