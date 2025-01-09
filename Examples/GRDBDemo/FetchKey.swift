@preconcurrency import Combine
import Dependencies
import GRDB
import Sharing
import SwiftUI

extension SharedReaderKey {
  /// A key that can query for data in a SQLite database.
  static func fetch<Value>(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value> {
    FetchKey(request: request, database: database, animation: animation)
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func fetch<Value: RangeReplaceableCollection>(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value>.Default {
    Self[.fetch(request, database: database, animation: animation), default: Value()]
  }

  /// A key that can query for a collection of data in a SQLite database.
  static func fetchAll<Value: FetchableRecord>(
    sql: String,
    arguments: StatementArguments = StatementArguments(),
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<[Value]>.Default {
    Self[
      .fetch(FetchAll(sql: sql, arguments: arguments), database: database, animation: animation),
      default: []
    ]
  }

  /// A key that can query for a value in a SQLite database.
  static func fetchOne<Value: DatabaseValueConvertible>(
    sql: String,
    arguments: StatementArguments = StatementArguments(),
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) -> Self
  where Self == FetchKey<Value> {
    .fetch(FetchOne(sql: sql, arguments: arguments), database: database, animation: animation)
  }
}

extension DependencyValues {
  /// The default database used by ``Sharing/SharedReaderKey/fetch(_:animation:)``.
  public var defaultDatabase: any DatabaseWriter {
    get { self[DefaultDatabaseKey.self] }
    set { self[DefaultDatabaseKey.self] = newValue }
  }

  private enum DefaultDatabaseKey: DependencyKey {
    static var liveValue: any DatabaseWriter { testValue }
    static var testValue: any DatabaseWriter {
      reportIssue(
        """
        A blank, in-memory database is being used. To set the database that is used by the 'fetch' \
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

protocol FetchKeyRequest<Value>: Hashable, Sendable {
  associatedtype Value
  func fetch(_ db: Database) throws -> Value
}

struct FetchKey<Value: Sendable>: SharedReaderKey {
  let database: any DatabaseReader
  let request: any FetchKeyRequest<Value>
  let scheduler: any ValueObservationScheduler
  #if DEBUG
    let isDefaultDatabase: Bool
  #endif

  typealias ID = FetchKeyID

  var id: ID { ID(rawValue: request) }

  init(
    request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    animation: Animation? = nil
  ) {
    @Dependency(\.defaultDatabase) var defaultDatabase
    self.scheduler = .animation(animation)
    self.database = database ?? defaultDatabase
    self.request = request
    #if DEBUG
      self.isDefaultDatabase = self.database.configuration.label == .defaultDatabaseLabel
    #endif
  }

  func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    #if DEBUG
      guard !isDefaultDatabase else {
        continuation.resumeReturningInitialValue()
        return
      }
    #endif
    guard case .userInitiated = context else {
      continuation.resumeReturningInitialValue()
      return
    }
    guard !isTesting else {
      continuation.resume(with: Result { try database.read(request.fetch) })
      return
    }
    database.asyncRead { dbResult in
      let result = dbResult.flatMap { db in
        Result { try request.fetch(db) }
      }
      scheduler.schedule { continuation.resume(with: result.map(Optional.some)) }
    }
  }

  func subscribe(
    context: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    #if DEBUG
      guard !isDefaultDatabase else {
        return SharedSubscription {}
      }
    #endif
    let observation = ValueObservation.tracking(request.fetch)
    let dropFirst =
      switch context {
      case .initialValue: false
      case .userInitiated: true
      }
    let cancellable = observation.publisher(in: database, scheduling: scheduler)
      .dropFirst(dropFirst ? 1 : 0)
      .sink { completion in
        switch completion {
        case let .failure(error):
          subscriber.yield(throwing: error)
        case .finished:
          break
        }
      } receiveValue: { newValue in
        subscriber.yield(newValue)
      }
    return SharedSubscription {
      cancellable.cancel()
    }
  }
}

struct FetchKeyID: Hashable {
  fileprivate let rawValue: AnyHashableSendable

  init(rawValue: any FetchKeyRequest) {
    self.rawValue = AnyHashableSendable(rawValue)
  }
}

private struct FetchAll<Element: FetchableRecord>: FetchKeyRequest {
  var sql: String
  var arguments: StatementArguments = StatementArguments()
  func fetch(_ db: Database) throws -> [Element] {
    try Element.fetchAll(db, sql: sql, arguments: arguments)
  }
}

private struct FetchOne<Value: DatabaseValueConvertible>: FetchKeyRequest {
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
