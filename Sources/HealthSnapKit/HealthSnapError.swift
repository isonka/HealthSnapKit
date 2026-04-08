import Foundation

/// Errors surfaced by HealthSnapKit when HealthKit is unavailable, authorization fails, or queries return no data.
public enum HealthSnapError: Error, Sendable {
    /// HealthKit is not available on this device.
    case notAvailable
    /// The user has not granted read access for the requested data types.
    case notAuthorized
    /// No samples were found for the requested range or filters.
    case noData
    /// The underlying HealthKit query failed.
    case queryFailed(Error)
}

extension HealthSnapError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "HealthKit read access was not granted for the requested data."
        case .noData:
            return "No HealthKit data was found for the requested range."
        case .queryFailed(let error):
            return "A HealthKit query failed: \(error.localizedDescription)"
        }
    }
}
