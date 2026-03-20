import Foundation
import PerceptionCore

@_spi(Navigation) extension Shared {
  public var _uiBindingRoot: _SharedUIBindingRoot<Value> {
    box.uiBindingRoot
  }
}

@_spi(Navigation) public final class _SharedUIBindingRoot<Value>: Perceptible, @unchecked Sendable {
  private let _$perceptionRegistrar = PerceptionRegistrar()
  private let lock = NSRecursiveLock()
  private var reference: any MutableReference<Value>

  init(reference: any MutableReference<Value>) {
    self.reference = reference
    observeReference()
  }

  public var value: Value {
    get {
      _$perceptionRegistrar.access(self, keyPath: \.value)
      lock.lock()
      let reference = self.reference
      lock.unlock()
      return reference._untrackedWrappedValue()
    }
    set {
      lock.lock()
      let reference = self.reference
      lock.unlock()
      reference.withLock { $0 = newValue }
    }
  }

  func setReference(_ newReference: any MutableReference<Value>) {
    let didChange = lock.withLock {
      guard reference.id != newReference.id else { return false }
      reference = newReference
      return true
    }
    guard didChange else { return }
    observeReference()
    _$perceptionRegistrar.withMutation(of: self, keyPath: \.value) {}
  }

  private func observeReference() {
    lock.lock()
    let reference = self.reference
    lock.unlock()
    withPerceptionTracking {
      _ = reference.wrappedValue
    } onChange: { [weak self] in
      guard let self else { return }
      self._$perceptionRegistrar.withMutation(of: self, keyPath: \.value) {}
      self.observeReference()
    }
  }
}

#if canImport(Observation)
  extension _SharedUIBindingRoot: Observable {}
#endif
