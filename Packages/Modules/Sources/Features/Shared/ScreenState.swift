/// Shared, explicit lifecycle state for list screens — never nil-inferred.
public enum ScreenState: Equatable {
    case loading
    case loaded
    case empty
    case failed(message: String, retryable: Bool)
}
