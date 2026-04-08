import Foundation
import HealthKit

/// Async wrappers around completion-handler-based HealthKit queries (used by ``LiveHealthStore``).
enum HKQueryAsync {
    static func statisticsCollection(
        store: HKHealthStore,
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) async throws -> HKStatisticsCollection {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDate,
                intervalComponents: intervalComponents
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    if HKError.isNoMatchingSamples(error) {
                        continuation.resume(throwing: HealthSnapError.noData)
                    } else {
                        continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    }
                    return
                }
                guard let collection else {
                    continuation.resume(throwing: HealthSnapError.noData)
                    return
                }
                continuation.resume(returning: collection)
            }
            store.execute(query)
        }
    }

    static func statistics(
        store: HKHealthStore,
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, stats, error in
                if let error {
                    if HKError.isNoMatchingSamples(error) {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    }
                    return
                }
                continuation.resume(returning: stats)
            }
            store.execute(query)
        }
    }

    static func samples(
        store: HKHealthStore,
        sampleType: HKSampleType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    if HKError.isNoMatchingSamples(error) {
                        continuation.resume(returning: [])
                    } else {
                        continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    }
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }
}
