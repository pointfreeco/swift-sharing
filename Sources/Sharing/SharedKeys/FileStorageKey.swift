#if canImport(AppKit) || canImport(UIKit) || canImport(WatchKit)
  import CombineSchedulers
  import Dependencies
  @preconcurrency import Dispatch

  #if canImport(AppKit)
    import AppKit
  #endif
  #if canImport(UIKit)
    import UIKit
  #endif
  #if canImport(WatchKit)
    import WatchKit
  #endif

  extension SharedReaderKey {
    /// Creates a shared key that can read and write to a `Codable` value in the file system.
    ///
    /// For example:
    ///
    /// ```swift
    /// struct Settings: Codable {
    ///   var hapticsEnabled = true
    ///   // ...
    /// }
    ///
    /// @Shared(.fileStorage(.documentsDirectory.appending(component: "settings.json"))
    /// var settings = Settings()
    /// ```
    ///
    /// - Parameters:
    ///   - url: The file URL from which to read and write the value.
    ///   - decoder: The JSONDecoder to use for decoding the value.
    ///   - encoder: The JSONEncoder to use for encoding the value.
    /// - Returns: A file shared key.
    public static func fileStorage<Value: Codable>(
      _ url: URL,
      decoder: JSONDecoder? = nil,
      encoder: JSONEncoder? = nil
    ) -> Self
    where Self == FileStorageKey<Value> {
      let decoder = decoder ?? JSONDecoder()
      let encoder = encoder ?? _defaultEncoder
      return fileStorage(
        url,
        decode: { try decoder.decode(Value.self, from: $0) },
        encode: { try encoder.encode($0) }
      )
    }

    /// Creates a shared key that can read and write to a value in the file system.
    ///
    /// - Parameters:
    ///   - url: The file URL from which to read and write the value.
    ///   - decode: The closure to use for decoding the value.
    ///   - encode: The closure to use for encoding the value.
    /// - Returns: A file shared key.
    public static func fileStorage<Value>(
      _ url: URL,
      decode: @escaping @Sendable (Data) throws -> Value,
      encode: @escaping @Sendable (Value) throws -> Data
    ) -> Self
    where Self == FileStorageKey<Value> {
      FileStorageKey(url: url, decode: decode, encode: encode)
    }
  }

  /// A type defining a file persistence strategy
  ///
  /// Use ``SharedReaderKey/fileStorage(_:decoder:encoder:)`` to create values of this type.
  public final class FileStorageKey<Value: Sendable>: SharedKey {
    private let storage: FileStorage
    private let url: URL
    private let decode: @Sendable (Data) throws -> Value
    private let encode: @Sendable (Value) throws -> Data
    fileprivate let state = LockIsolated(State())

    fileprivate struct State {
      var continuations: [SaveContinuation] = []
      var modificationDates: [Date] = []
      var value: Value?
      var workItem: DispatchWorkItem?
      mutating func cancelWorkItem() {
        value = nil
        workItem?.cancel()
        workItem = nil
      }
    }

    public var id: FileStorageKeyID {
      FileStorageKeyID(url: url, storage: storage)
    }

    fileprivate init(
      url: URL,
      decode: @escaping @Sendable (Data) throws -> Value,
      encode: @escaping @Sendable (Value) throws -> Data
    ) {
      @Dependency(\.defaultFileStorage) var storage
      self.storage = storage
      self.url = url
      self.decode = decode
      self.encode = encode
    }

    public func load(context _: LoadContext<Value>, continuation: LoadContinuation<Value>) {
      guard
        let data = try? storage.load(url),
        data != stubBytes
      else {
        continuation.resumeReturningInitialValue()
        return
      }
      continuation.resume(with: Result { try decode(data) })
    }

    public func subscribe(
      context _: LoadContext<Value>, subscriber: SharedSubscriber<Value>
    ) -> SharedSubscription {
      let cancellable = LockIsolated<SharedSubscription?>(nil)
      @Sendable func setUpSources() {
        cancellable.withValue { [weak self] in
          $0?.cancel()
          guard let self else { return }
          do {
            // NB: Make sure there is a file to create a source for.
            if !storage.fileExists(url) {
              try storage.createDirectory(url.deletingLastPathComponent(), true)
              try storage.save(stubBytes, url)
            }
            let writeCancellable = try storage.fileSystemSource(url, [.write]) { [weak self] in
              guard let self else { return }
              state.withValue { state in
                let modificationDate =
                  (try? storage.attributesOfItemAtPath(url.path)[.modificationDate]
                    as? Date)
                  ?? Date.distantPast
                guard
                  !state.modificationDates.contains(modificationDate)
                else {
                  state.modificationDates.removeAll(where: { $0 <= modificationDate })
                  return
                }

                guard state.workItem == nil
                else { return }

                subscriber.yield(with: Result { try decode(storage.load(url)) })
              }
            }
            let deleteCancellable = try storage.fileSystemSource(url, [.delete, .rename]) {
              [weak self] in
              guard let self else { return }
              state.withValue { state in
                state.cancelWorkItem()
              }
              subscriber.yield(with: .success(try? decode(storage.load(url))))
              setUpSources()
            }
            $0 = SharedSubscription {
              writeCancellable.cancel()
              deleteCancellable.cancel()
            }
          } catch {
            subscriber.yield(throwing: error)
          }
        }
      }
      setUpSources()
      return SharedSubscription {
        cancellable.withValue { $0?.cancel() }
      }
    }

    private func save(data: Data, url: URL, modificationDates: inout [Date]) throws {
      try storage.save(data, url)
      if let modificationDate = try storage.attributesOfItemAtPath(url.path)[.modificationDate]
        as? Date
      {
        modificationDates.append(modificationDate)
      }
    }

    public func save(_ value: Value, context: SaveContext, continuation: SaveContinuation) {
      do {
        try state.withValue { state in
          let data = try encode(value)
          switch context {
          case .didSet:
            if state.workItem == nil {
              try save(data: data, url: url, modificationDates: &state.modificationDates)
              continuation.resume()
              let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.state.withValue { state in
                  defer {
                    state.value = nil
                    state.workItem = nil
                  }
                  guard
                    let value = state.value,
                    let data = try? encode(value)
                  else { return }
                  let result = Result {
                    try save(
                      data: data,
                      url: url,
                      modificationDates: &state.modificationDates
                    )
                  }
                  for continuation in state.continuations {
                    continuation.resume(with: result)
                  }
                  state.continuations.removeAll()
                }
              }
              state.workItem = workItem
              storage.asyncAfter(.seconds(1), workItem)
            } else {
              state.value = value
              state.continuations.append(continuation)
            }

          case .userInitiated:
            state.cancelWorkItem()
            try storage.save(data, url)
            continuation.resume()
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }

    private func performImmediately() {
      state.withValue { state in
        guard let workItem = state.workItem
        else { return }
        storage.async(workItem)
        storage.async(
          DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.state.withValue { state in
              state.cancelWorkItem()
            }
          }
        )
      }
    }
  }

  extension FileStorageKey: CustomStringConvertible {
    public var description: String {
      ".fileStorage(\(String(reflecting: url)))"
    }
  }

  public struct FileStorageKeyID: Hashable {
    fileprivate let url: URL
    fileprivate let storage: FileStorage
  }

  private enum FileStorageDependencyKey: DependencyKey {
    static var liveValue: FileStorage {
      .fileSystem
    }
    static var previewValue: FileStorage {
      .inMemory
    }
    static var testValue: FileStorage {
      .inMemory
    }
  }

  extension DependencyValues {
    /// Default file storage used by ``SharedReaderKey/fileStorage(_:decoder:encoder:)``.
    ///
    /// Use this dependency to override the manner in which
    /// ``SharedReaderKey/fileStorage(_:decoder:encoder:)`` interacts with file storage. For
    /// example, while your app is running for UI tests you probably do not want your features writing
    /// changes to disk, which would cause that data to bleed over from test to test.
    ///
    /// So, for that situation you can use the ``FileStorage/inMemory`` file storage so that each
    /// run of the app starts with a fresh "file system" that will never interfere with other tests:
    ///
    /// ```swift
    /// import Dependencies
    /// import Sharing
    /// import SwiftUI
    ///
    /// @main
    /// struct MyApp: App {
    ///   init() {
    ///     if ProcessInfo.processInfo.environment["UITesting"] == "true"
    ///       prepareDependencies {
    ///         $0.defaultFileStorage = .inMemory
    ///       }
    ///     }
    ///   }
    ///   // ...
    /// }
    /// ```
    public var defaultFileStorage: FileStorage {
      get { self[FileStorageDependencyKey.self] }
      set { self[FileStorageDependencyKey.self] = newValue }
    }
  }

  /// A type that encapsulates saving and loading data from disk.
  public struct FileStorage: Hashable, Sendable {
    let id: AnyHashableSendable
    let async: @Sendable (DispatchWorkItem) -> Void
    let asyncAfter: @Sendable (DispatchTimeInterval, DispatchWorkItem) -> Void
    let attributesOfItemAtPath: @Sendable (String) throws -> [FileAttributeKey: Any]
    let createDirectory: @Sendable (URL, Bool) throws -> Void
    let fileExists: @Sendable (URL) -> Bool
    let fileSystemSource:
      @Sendable (URL, DispatchSource.FileSystemEvent, @escaping @Sendable () -> Void) throws ->
        SharedSubscription
    let load: @Sendable (URL) throws -> Data
    @_spi(Internals) public let save: @Sendable (Data, URL) throws -> Void

    /// File storage that interacts directly with the file system for saving, loading and listening
    /// for file changes.
    ///
    /// This is the version of the ``Dependencies/DependencyValues/defaultFileStorage`` dependency
    /// that is used by default when running your app in the simulator or on device.
    public static let fileSystem = Self(
      id: AnyHashableSendable(DispatchQueue.main),
      async: { DispatchQueue.main.async(execute: $0) },
      asyncAfter: { DispatchQueue.main.asyncAfter(deadline: .now() + $0, execute: $1) },
      attributesOfItemAtPath: { try FileManager.default.attributesOfItem(atPath: $0) },
      createDirectory: {
        try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: $1)
      },
      fileExists: { FileManager.default.fileExists(atPath: $0.path) },
      fileSystemSource: {
        let fileDescriptor = open($0.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
          struct FileDescriptorError: Error {}
          throw FileDescriptorError()
        }
        let source = DispatchSource.makeFileSystemObjectSource(
          fileDescriptor: fileDescriptor,
          eventMask: $1,
          queue: DispatchQueue.main
        )
        source.setEventHandler(handler: $2)
        source.resume()
        return SharedSubscription {
          source.cancel()
          close(source.handle)
        }
      },
      load: { try Data(contentsOf: $0) },
      save: { try $0.write(to: $1) }
    )

    /// File storage that emulates a file system without actually writing anything to disk.
    ///
    /// This is the version of the ``Dependencies/DependencyValues/defaultFileStorage`` dependency
    /// that is used by default when running your app in tests and previews.
    public static var inMemory: Self {
      inMemory(fileSystem: LockIsolated([:]))
    }

    @_spi(Internals) public static func inMemory(
      fileSystem: LockIsolated<[URL: Data]>,
      scheduler: AnySchedulerOf<DispatchQueue> = .immediate
    ) -> Self {
      return Self(
        id: AnyHashableSendable(ObjectIdentifier(fileSystem)),
        async: { scheduler.schedule($0.perform) },
        asyncAfter: {
          scheduler.schedule(after: scheduler.now.advanced(by: .init($0)), $1.perform)
        },
        attributesOfItemAtPath: { _ in [:] },
        createDirectory: { _, _ in },
        fileExists: { fileSystem.keys.contains($0) },
        fileSystemSource: { url, event, handler in
          guard event.contains(.write)
          else { return SharedSubscription {} }
          return SharedSubscription {}
        },
        load: {
          guard let data = fileSystem[$0]
          else {
            struct LoadError: Error {}
            throw LoadError()
          }
          return data
        },
        save: { data, url in
          fileSystem.withValue { $0[url] = data }
        }
      )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }

  private let _defaultEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    #if DEBUG
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    #endif
    return encoder
  }()

  private let stubBytes = Data("co.pointfree.Sharing.FileStorage.stub".utf8)
#endif
