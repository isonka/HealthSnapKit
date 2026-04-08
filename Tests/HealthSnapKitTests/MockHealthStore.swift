import Foundation
import HealthKit
@testable import HealthSnapKit

/// Test double for ``HealthStoreProtocol`` that never touches a real ``HKHealthStore``.
final class MockHealthStore: HealthStoreProtocol {
    var healthDataAvailable = true
    var statisticsCollectionImpl: (
        (HKQuantityType, NSPredicate, HKStatisticsOptions, Date, DateComponents) async throws -> HKStatisticsCollection
    )?
    var statisticsImpl: ((HKQuantityType, NSPredicate, HKStatisticsOptions) async throws -> HKStatistics?)?
    var samplesImpl: ((HKSampleType, NSPredicate, Int, [NSSortDescriptor]) async throws -> [HKSample])?

    func isHealthDataAvailable() -> Bool {
        healthDataAvailable
    }

    func requestAuthorization(
        toShare: Set<HKSampleType>,
        read: Set<HKObjectType>,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        completion(true, nil)
    }

    func statisticsCollection(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) async throws -> HKStatisticsCollection {
        guard let statisticsCollectionImpl else {
            throw HealthSnapError.noData
        }
        return try await statisticsCollectionImpl(quantityType, predicate, options, anchorDate, intervalComponents)
    }

    func statistics(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        guard let statisticsImpl else {
            return nil
        }
        return try await statisticsImpl(quantityType, predicate, options)
    }

    func samples(
        sampleType: HKSampleType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKSample] {
        guard let samplesImpl else {
            return []
        }
        return try await samplesImpl(sampleType, predicate, limit, sortDescriptors)
    }
}
