import Dependencies
import GRDB
import Sharing
import SwiftUI

extension SharedReaderKey {
  /// A key that can query for data in a SQLite database.
  static func query<Value>(
    _ query: some GRDBQuery<Value>,
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<Value> {
    GRDBQueryKey(query: query, animation: animation)
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func query<Value: RangeReplaceableCollection>(
    _ query: some GRDBQuery<Value>,
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<Value>.Default {
    Self[.query(query, animation: animation), default: Value()]
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func fetchAll<Value: FetchableRecord>(
    sql: String,
    arguments: StatementArguments = StatementArguments(),
    animation: Animation? = nil
  ) -> Self
  where Self == GRDBQueryKey<[Value]>.Default {
    Self[.query(FetchAll(sql: sql, arguments: arguments), animation: animation), default: []]
  }

  /// A key that can query for a value in a SQLite database.
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
  /// The default database used by ``Sharing/SharedReaderKey/query(_:animation:)``.
  public var defaultDatabase: any DatabaseWriter {
    get { self[GRDBDatabaseKey.self] }
    set { self[GRDBDatabaseKey.self] = newValue }
  }

  private enum GRDBDatabaseKey: DependencyKey {
    static var liveValue: any DatabaseWriter { testValue }
    static var testValue: any DatabaseWriter {
      reportIssue(
        """
        A blank, in-memory database is being used. To set the database that is used by the 'query' \
        key you can use the 'prepareDependencies' tool as soon as your app launches, such as in \
        your app or scene delegate in UIKit, or the app entry point in SwiftUI:

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
      var configuration = Configuration()
      configuration.label = .defaultDatabaseLabel
      return try! DatabaseQueue(configuration: configuration)
    }
  }
}

protocol GRDBQuery<Value>: Hashable, Sendable {
  associatedtype Value
  func fetch(_ db: Database) throws -> Value
}

struct GRDBQueryKey<Value: Sendable>: SharedReaderKey {
  let database: any DatabaseWriter
  let query: any GRDBQuery<Value>
  let scheduler: any ValueObservationScheduler
  #if DEBUG
    let isDefaultDatabase: Bool
  #endif

  typealias ID = GRDBQueryID

  var id: ID { ID(rawValue: query) }

  init(query: some GRDBQuery<Value>, animation: Animation? = nil) {
    @Dependency(\.defaultDatabase) var database
    self.scheduler = .animation(animation)
    self.database = database
    self.query = query
    #if DEBUG
      self.isDefaultDatabase = database.configuration.label == .defaultDatabaseLabel
    #endif
  }

  func load(
    initialValue: Value?,
    didReceive callback: @escaping @Sendable (Result<Value?, any Error>) -> Void
  ) {
    #if DEBUG
      guard !isDefaultDatabase else {
        callback(.success(nil))
        return
      }
    #endif
    database.asyncRead { result in
      let result: Result<Value?, any Error> = result.flatMap { db in
        Result { try query.fetch(db) }
      }
      scheduler.schedule { callback(result) }
    }
  }

  func subscribe(
    initialValue: Value?,
    didReceive callback: @escaping @Sendable (Result<Value?, any Error>) -> Void
  ) -> SharedSubscription {
    #if DEBUG
      guard !isDefaultDatabase else {
        return SharedSubscription {}
      }
    #endif
    let observation = ValueObservation.tracking(query.fetch)
    let cancellable = observation.start(in: database, scheduling: scheduler) { error in
      callback(.failure(error))
    } onChange: { newValue in
      callback(.success(newValue))
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

#if DEBUG
  extension String {
    fileprivate static let defaultDatabaseLabel = "co.pointfree.SharingGRDB.testValue"
  }
#endif
