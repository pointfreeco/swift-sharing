import Dependencies
import GRDB
import Sharing
import SwiftUI

extension SharedReaderKey {
  /// A shared key that can query for data in a SQLite database.
  static func query<Value>(
    _ query: some GRDBQuery<Value>,
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<Value> {
    GRDBQueryKey(query: query, animation: animation)
  }

  /// A shared key that can query for data in a SQLite database.
  static func query<Value: RangeReplaceableCollection>(
    _ query: some GRDBQuery<Value>,
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<Value>.Default {
    Self[.query(query, animation: animation), default: Value()]
  }

  /// A shared key that can query for data in a SQLite database.
  static func fetchAll<Value: FetchableRecord>(
    sql: String,
    arguments: StatementArguments = StatementArguments(),
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<[Value]>.Default {
    Self[.query(FetchAll(sql: sql, arguments: arguments), animation: animation), default: []]
  }

  /// A shared key that can query for data in a SQLite database.
  static func fetchOne<Value: DatabaseValueConvertible>(
    sql: String,
    arguments: StatementArguments = StatementArguments(),
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<Value> {
    .query(FetchOne(sql: sql, arguments: arguments), animation: animation)
  }
}

extension DependencyValues {
  /// The default database used by ``Sharing/SharedReaderKey/grdbQuery(_:animation:)``.
  public var defaultDatabase: any DatabaseWriter {
    get { self[GRDBDatabaseKey.self] }
    set { self[GRDBDatabaseKey.self] = newValue }
  }

  private enum GRDBDatabaseKey: DependencyKey {
    static var liveValue: any DatabaseWriter {
      reportIssue(
        """
        A blank, in-memory database is being used for the app. To set the database that is used by \
        the 'grdbQuery' key you can use the 'prepareDependencies' tool as soon as your app \ 
        launches, such as in your app or scene delegate in UIKit, or the app entry point in SwiftUI:

            @main
            struct MyApp: App {
              init() {
                prepareDependencies {
                  $0.defaultDatabase = try! DatabaseQueue(/* ... */)
                }
              }

              // ...
            }
        """
      )
      return try! DatabaseQueue()
    }

    static var testValue: any DatabaseWriter {
      try! DatabaseQueue()
    }
  }
}

protocol GRDBQuery<Value>: Hashable, Sendable {
  associatedtype Value
  func fetch(_ db: Database) throws -> Value
}

struct GRDBQueryKey<Value: Sendable>: SharedReaderKey {
  let animation: Animation?
  let databaseQueue: any DatabaseWriter
  let query: any GRDBQuery<Value>

  typealias ID = GRDBQueryID

  var id: ID { ID(rawValue: query) }

  init(query: some GRDBQuery<Value>, animation: Animation? = nil) {
    @Dependency(\.defaultDatabase) var databaseQueue
    self.animation = animation
    self.databaseQueue = databaseQueue
    self.query = query
  }

  func load(initialValue: Value?) -> Value? {
    (try? databaseQueue.read(query.fetch)) ?? initialValue
  }

  func subscribe(
    initialValue: Value?,
    didSet receiveValue: @escaping @Sendable (Value?) -> Void
  ) -> SharedSubscription {
    let observation = ValueObservation.tracking(query.fetch)
    let cancellable = observation.start(
      in: databaseQueue,
      scheduling: .animation(animation)
    ) { error in
      reportIssue(error)
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

  init(rawValue: any GRDBQuery) {
    self.rawValue = AnyHashableSendable(rawValue)
  }
}

private struct FetchAll<Element: FetchableRecord>: GRDBQuery {
  var sql: String
  var arguments: StatementArguments = StatementArguments()
  func fetch(_ db: Database) throws -> [Element] {
    try Element.fetchAll(db, sql: sql, arguments: arguments)
  }
}

private struct FetchOne<Value: DatabaseValueConvertible>: GRDBQuery {
  var sql: String
  var arguments: StatementArguments = StatementArguments()
  func fetch(_ db: Database) throws -> Value {
    guard let value = try Value.fetchOne(db, sql: sql, arguments: arguments)
    else { throw NotFound() }
    return value
  }
  struct NotFound: Error {}
}

private struct AnimatedScheduler: ValueObservationScheduler {
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
  fileprivate static func animation(_ animation: Animation?) -> Self {
    AnimatedScheduler(animation: animation)
  }
}
