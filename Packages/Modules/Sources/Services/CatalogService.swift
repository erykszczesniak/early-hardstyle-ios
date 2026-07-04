import Core
import Foundation

/// Loads the hardstyle catalogue. Features depend on this protocol; the live
/// implementation (bundled JSON now, a networked API later) is chosen at the
/// composition root and swapped for a mock in tests.
public protocol CatalogService: Sendable {
    /// Loads the full catalogue, or throws a ``CatalogError``.
    func loadCatalog() async throws -> Catalog
}

/// Typed catalogue-loading errors, mapped from transport/decoding failures so
/// the UI can present a designed message and decide whether to offer retry.
public enum CatalogError: Error, Equatable, Sendable {
    case offline
    case timedOut
    case decodingFailed(String)
    case server(statusCode: Int)
    case unknown

    /// Whether a retry could plausibly succeed (transient failures only).
    public var isRetryable: Bool {
        switch self {
        case .offline, .timedOut, .server, .unknown: true
        case .decodingFailed: false
        }
    }

    /// Maps any thrown error into a typed `CatalogError`, so every failure —
    /// transport, decoding or otherwise — surfaces as a designed, retryable-aware
    /// state. Passes an existing `CatalogError` through unchanged.
    public static func from(_ error: Error) -> CatalogError {
        if let catalogError = error as? CatalogError {
            return catalogError
        }
        if error is DecodingError {
            return .decodingFailed(String(describing: error))
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return .offline
            case .timedOut:
                return .timedOut
            default:
                return .unknown
            }
        }
        return .unknown
    }
}

extension CatalogError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .offline:
            L10n.errorOffline
        case .timedOut:
            L10n.errorTimedOut
        case let .decodingFailed(detail):
            L10n.errorDecoding(detail)
        case let .server(statusCode):
            L10n.errorServer(statusCode: statusCode)
        case .unknown:
            L10n.errorUnknown
        }
    }
}

/// In-memory catalogue service for tests, previews and driving explicit UI
/// states (loaded / empty / error / slow). Deterministic and dependency-free.
public struct MockCatalogService: CatalogService {
    public enum Behaviour: Sendable {
        case success(Catalog)
        case failure(CatalogError)
    }

    private let behaviour: Behaviour
    private let delay: Duration

    public init(_ behaviour: Behaviour, delay: Duration = .zero) {
        self.behaviour = behaviour
        self.delay = delay
    }

    /// Convenience: succeeds with the given catalogue.
    public static func returning(_ catalog: Catalog, delay: Duration = .zero) -> MockCatalogService {
        MockCatalogService(.success(catalog), delay: delay)
    }

    /// Convenience: fails with the given error.
    public static func failing(_ error: CatalogError, delay: Duration = .zero) -> MockCatalogService {
        MockCatalogService(.failure(error), delay: delay)
    }

    public func loadCatalog() async throws -> Catalog {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        switch behaviour {
        case let .success(catalog): return catalog
        case let .failure(error): throw error
        }
    }
}
