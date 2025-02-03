// NB: Deprecated after 2.2.0

extension SharedReader {
  #if compiler(>=6)
    @available(*, deprecated, message: "Use 'SharedReader(value:)', instead.")
    public static func constant(_ value: sending Value) -> Self {
      Self(Shared(value: value))
    }
  #else
    @available(*, deprecated, message: "Use 'SharedReader(value:)', instead.")
    public static func constant(_ value: Value) -> Self {
      Self(Shared(value: value))
    }
  #endif
}
