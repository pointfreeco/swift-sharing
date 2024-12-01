#if canImport(SwiftUI)
  import PerceptionCore
  import SwiftUI

  extension Binding {
    /// Creates a binding from a shared reference.
    ///
    /// Useful for binding shared state to a SwiftUI control.
    ///
    /// ```swift
    /// @Shared var count: Int
    /// // ...
    /// Stepper("\(count)", value: Binding($count))
    /// ```
    ///
    /// - Parameter base: A shared reference to a value.
    @MainActor
    public init(_ base: Shared<Value>) {
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
        // NB: We can't do 'any MutableReference<Value> & Observable' and must force-cast, instead.
        //     https://github.com/swiftlang/swift/pull/76705
        let reference = base.reference as? any MutableReference & Observable
      {
        func open<V>(_ reference: some MutableReference<V> & Observable) -> Binding<Value> {
          @SwiftUI.Bindable var reference = reference
          return $reference._wrappedValue as! Binding<Value>
        }
        self = open(reference)
      } else {
        func open(_ reference: some MutableReference<Value>) -> Binding<Value> {
          @PerceptionCore.Bindable var reference = reference
          return $reference._wrappedValue
        }
        self = open(base.reference)
      }
    }
  }

  extension MutableReference {
    fileprivate var _wrappedValue: Value {
      get { wrappedValue }
      set { withLock { $0 = newValue } }
    }
  }
#endif
