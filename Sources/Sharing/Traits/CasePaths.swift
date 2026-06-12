//#if CasePaths
public import CasePaths

#if canImport(Combine)
  import Combine
#endif

extension Shared {
  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
  ) -> Shared<Member>?
  where Value: CasePathable {
    func open(_ reference: some MutableReference<Value>) -> Shared<Member?> {
      Shared<Member?>(
        reference: _MutableReferenceEnumToOptionalCase(base: reference, keyPath: keyPath.unsafeSendable())
      )
    }
    return Shared<Member>(open(reference))
  }
}

extension SharedReader {
  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
  ) -> SharedReader<Member>?
  where Value: CasePathable {
    func open(_ reference: some Reference<Value>) -> SharedReader<Member?> {
      SharedReader<Member?>(
        reference: _ReferenceEnumToOptionalCase(base: reference, keyPath: keyPath.unsafeSendable())
      )
    }
    return SharedReader<Member>(open(reference))
  }
}

private final class _ReferenceEnumToOptionalCase<Base: Reference, Case>
where Base.Value: CasePathable {
  typealias Value = Case?
  let base: Base
  let keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  let casePath: AnyCasePath<Base.Value, Case>
  
  init(
    base: Base, keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  ) {
    self.base = base
    self.keyPath = keyPath
    self.casePath = Base.Value.allCasePaths[keyPath: keyPath]
  }
}

extension _ReferenceEnumToOptionalCase: CustomStringConvertible {
  var description: String {
    "\(base.description)[dynamicMember: \(keyPath)]"
  }
}

extension _ReferenceEnumToOptionalCase: Reference {
  var id: ObjectIdentifier {
    base.id
  }
  
  var isLoading: Bool {
    base.isLoading
  }
  
  var loadError: (any Error)? {
    base.loadError
  }
  
  var wrappedValue: Value {
    casePath.extract(from: base.wrappedValue)
  }
  
  func load() async throws {
    try await base.load()
  }
  
  func touch() {
    base.touch()
  }
  
#if canImport(Combine)
  var publisher: any Publisher<Value, Never> {
    func open(
      _ publisher: some Publisher<Base.Value, Never>,
      extract: @escaping @Sendable (Base.Value) -> Value
    ) -> any Publisher<Value, Never> {
      publisher.map(extract)
    }
    return open(
      base.publisher,
      extract: { [casePath] in
        casePath.extract(from: $0)
      }
    )
  }
#endif
}

private final class _MutableReferenceEnumToOptionalCase<Base: MutableReference, Case>
where Base.Value: CasePathable {
  typealias Value = Case?
  let base: Base
  let keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  let casePath: AnyCasePath<Base.Value, Case>
  
  init(
    base: Base, keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  ) {
    self.base = base
    self.keyPath = keyPath
    self.casePath = Base.Value.allCasePaths[keyPath: keyPath]
  }
}

extension _MutableReferenceEnumToOptionalCase: CustomStringConvertible {
  var description: String {
    "\(base.description)[dynamicMember: \(keyPath)]"
  }
}

extension _MutableReferenceEnumToOptionalCase: Reference {
  var id: ObjectIdentifier {
    base.id
  }
  
  var isLoading: Bool {
    base.isLoading
  }
  
  var loadError: (any Error)? {
    base.loadError
  }
  
  var wrappedValue: Value {
    casePath.extract(from: base.wrappedValue)
  }
  
  func load() async throws {
    try await base.load()
  }
  
  func touch() {
    base.touch()
  }
  
#if canImport(Combine)
  var publisher: any Publisher<Value, Never> {
    func open(
      _ publisher: some Publisher<Base.Value, Never>,
      extract: @escaping @Sendable (Base.Value) -> Value
    ) -> any Publisher<Value, Never> {
      publisher.map(extract)
    }
    return open(
      base.publisher,
      extract: { [casePath] in
        casePath.extract(from: $0)
      }
    )
  }
#endif
}
  
extension _MutableReferenceEnumToOptionalCase: MutableReference {
  var saveError: (any Error)? {
    base.saveError
  }
  
  var snapshot: Value? {
    base.snapshot.flatMap {
      casePath.extract(from: $0)
    }
  }
  
  func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    try base.withLock { value in
      var `case` = casePath.extract(from: value)
      let result = try body(&`case`)
      if let `case` {
        value = casePath.embed(`case`)
      }
      return result
    }
  }
  func takeSnapshot(
    _ value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    guard let value = value.flatMap({ casePath.embed($0) }) else { return }
    base.takeSnapshot(
      value,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
  func save() async throws {
    try await base.save()
  }
  
  static func == (lhs: _MutableReferenceEnumToOptionalCase, rhs: _MutableReferenceEnumToOptionalCase) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
}

//#endif
