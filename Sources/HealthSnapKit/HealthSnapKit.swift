import Foundation
import Observation

/// Entry point for HealthSnapKit: authorization and typed providers for activity, sleep, heart, and body data.
///
/// The facade is main-actor isolated so it can be held from SwiftUI without cross-actor `Sendable` requirements.
@MainActor
@Observable
public final class HealthSnapKit {
    private let store: HealthStoreProtocol

    /// Daily movement and energy metrics.
    public let activity: ActivityProvider
    /// Sleep stages grouped by night.
    public let sleep: SleepProvider
    /// Heart rate, resting HR, HRV, and samples.
    public let heart: HeartProvider
    /// Body composition samples.
    public let body: BodyProvider

    /// Creates a kit using the shared live ``HKHealthStore`` wrapper.
    public convenience init() {
        self.init(healthStore: LiveHealthStore())
    }

    /// Creates a kit with a custom ``HealthStoreProtocol`` (useful for tests).
    public init(healthStore: HealthStoreProtocol) {
        self.store = healthStore
        self.activity = ActivityProvider(store: healthStore)
        self.sleep = SleepProvider(store: healthStore)
        self.heart = HeartProvider(store: healthStore)
        self.body = BodyProvider(store: healthStore)
    }

    /// Requests read access for every ``HealthDataDomain``.
    public func requestAuthorization() async throws {
        try await requestAuthorization(reading: Set(HealthDataDomain.allCases))
    }

    /// Requests read access for the given domains.
    public func requestAuthorization(reading domains: Set<HealthDataDomain>) async throws {
        guard store.isHealthDataAvailable() else {
            throw HealthSnapError.notAvailable
        }
        let read = HealthKitPermissions.objectTypes(for: domains)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: read) { success, error in
                if let error {
                    continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    return
                }
                if !success {
                    continuation.resume(throwing: HealthSnapError.notAuthorized)
                    return
                }
                continuation.resume()
            }
        }
    }
}
