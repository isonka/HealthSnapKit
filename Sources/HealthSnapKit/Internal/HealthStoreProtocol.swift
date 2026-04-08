import Foundation
import HealthKit

/// Abstraction over ``HKHealthStore`` so production code and tests share the same query surface.
public protocol HealthStoreProtocol: AnyObject {
    /// Whether HealthKit is available on this device.
    func isHealthDataAvailable() -> Bool

    /// Requests authorization to read and write the given types.
    func requestAuthorization(
        toShare: Set<HKSampleType>,
        read: Set<HKObjectType>,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    )

    /// Runs a statistics collection query and returns the resulting collection.
    func statisticsCollection(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) async throws -> HKStatisticsCollection

    /// Runs a statistics query for a single interval.
    func statistics(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics?

    /// Runs a sample query and returns matching samples.
    func samples(
        sampleType: HKSampleType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKSample]
}
