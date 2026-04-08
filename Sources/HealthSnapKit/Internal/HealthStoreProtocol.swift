import Foundation
import HealthKit

/// Abstraction over ``HKHealthStore`` so production code and tests share the same provider surface.
public protocol HealthStoreProtocol: AnyObject {
    /// Whether HealthKit is available on this device.
    func isHealthDataAvailable() -> Bool

    /// Requests authorization to read and write the given types.
    func requestAuthorization(
        toShare: Set<HKSampleType>,
        read: Set<HKObjectType>,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    )

    /// Enqueues a HealthKit query.
    func execute(_ query: HKQuery)
}
