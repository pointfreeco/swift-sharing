import Dependencies
import GRDB
import Sharing
import SwiftUI

extension DependencyValues {
  public var defaultDatabase: DatabaseQueue {
    get { self[GRDBDatabaseKey.self] }
    set { self[GRDBDatabaseKey.self] = newValue }
  }

  private enum GRDBDatabaseKey: DependencyKey {
    static var liveValue: DatabaseQueue {
      reportIssue("""
        A blank, in-memory database is being used for the app. To set the database that is used by \
        the 'grdbQuery' key you can use the 'prepareDependencies' tool as soon as your app \ 
        launches, such as in the entry point:
        
            @main
            struct EntryPoint: App {
              init() {
                prepareDependencies {
                  $0.defaultDatabase = DatabaseQueue(…)
                }
              }

              // ...
            }
        """)
      return try! DatabaseQueue()
    }

    static var testValue: DatabaseQueue {
      try! DatabaseQueue()
    }
  }
}

protocol GRDBQuery<Value>: Hashable, Sendable {
  associatedtype Value
  func fetch(_ db: Database) throws -> Value
}

extension SharedReaderKey {
  /// A shared key that can query for data in a SQLite database.
  static func grdbQuery<Query>(_ query: Query, animation: Animation? = nil) -> Self
  where Self == GRDBQueryKey<Query> {
    GRDBQueryKey(query: query, animation: animation)
  }
}

struct GRDBQueryKey<Query: GRDBQuery>: SharedReaderKey
where Query.Value: Sendable {
  typealias Value = Query.Value

  let animation: Animation?
  let databaseQueue: DatabaseQueue
  let query: Query

  typealias ID = GRDBQueryID

  var id: ID { ID(rawValue: query) }

  init(query: Query, animation: Animation? = nil) {
    @Dependency(\.defaultDatabase) var databaseQueue
    self.animation = animation
    self.databaseQueue = databaseQueue
    self.query = query
  }

  func load(initialValue: Query.Value?) -> Query.Value? {
    (try? databaseQueue.read(query.fetch)) ?? initialValue
  }

  func subscribe(
    initialValue: Query.Value?,
    didSet receiveValue: @escaping @Sendable (Query.Value?) -> Void
  ) -> SharedSubscription {
    let observation = ValueObservation.tracking(query.fetch)
    let cancellable = observation.start(
      in: databaseQueue,
      scheduling: .animation(animation)
    ) { error in

    } onChange: { newValue in
      receiveValue(newValue)
    }
    return SharedSubscription {
      cancellable.cancel()
    }
  }
}

struct GRDBQueryID: Hashable {
  fileprivate let rawValue: AnyHashableSendable

  init(rawValue: some GRDBQuery) {
    self.rawValue = AnyHashableSendable(rawValue)
  }
}

struct AnimatedScheduler: ValueObservationScheduler {
  let animation: Animation?
  func immediateInitialValue() -> Bool { true }
  func schedule(_ action: @escaping @Sendable () -> Void) {
    if let animation {
      DispatchQueue.main.async {
        withAnimation(animation) {
          action()
        }
      }
    } else {
      DispatchQueue.main.async(execute: action)
    }
  }
}

extension ValueObservationScheduler where Self == AnimatedScheduler {
  static func animation(_ animation: Animation?) -> Self {
    AnimatedScheduler(animation: animation)
  }
}
