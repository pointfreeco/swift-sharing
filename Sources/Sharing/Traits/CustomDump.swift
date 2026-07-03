#if CustomDump
  public import CustomDump

  extension Shared: CustomDumpRepresentable {
    public var customDumpValue: Any {
      wrappedValue
    }
  }

  extension Shared: _CustomDiffObject {
    public var _customDiffValues: (Any, Any) {
      (reference.snapshot ?? reference.wrappedValue, reference.wrappedValue)
    }

    public var _objectIdentifier: ObjectIdentifier {
      func open(_ reference: some MutableReference<Value>) -> ObjectIdentifier {
        reference.id
      }
      return open(reference)
    }
  }

  extension SharedReader: CustomDumpRepresentable {
    public var customDumpValue: Any {
      wrappedValue
    }
  }
#endif
