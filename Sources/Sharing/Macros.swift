import Observation

/// Defines and implements conformance of the Observable protocol.
@attached(extension, conformances: Observable, ObservableValue)
@attached(member, names: named(_$id), named(_$observationRegistrar), named(_$willModify), named(shouldNotifyObservers))
@attached(memberAttribute)
public macro ObservableValue() =
  #externalMacro(module: "SharingMacros", type: "ObservableValueMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro ObservationValueTracked() =
  #externalMacro(module: "SharingMacros", type: "ObservationValueTrackedMacro")

@attached(accessor, names: named(willSet))
public macro ObservationValueIgnored() =
  #externalMacro(module: "SharingMacros", type: "ObservationValueIgnoredMacro")
