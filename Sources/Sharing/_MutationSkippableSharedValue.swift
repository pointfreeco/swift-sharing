public protocol _MutationSkippableSharedValue {
    func shouldCallWithMutation(newValue: Self) -> Bool
}
