import Foundation
import HealthKit

/// Async wrappers around completion-handler-based HealthKit queries.
enum HKQueryAsync {
    static func statisticsCollection(
        store: HealthStoreProtocol,
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
                    continuation.resume(throwing: HealthSnapError.queryFailed(error))
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
        store: HealthStoreProtocol,
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, stats, error in
                if let error {
                    continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    return
                }
                continuation.resume(returning: stats)
            }
            store.execute(query)
        }
    }

    static func samples(
        store: HealthStoreProtocol,
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
                    continuation.resume(throwing: HealthSnapError.queryFailed(error))
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }

    static func categorySamples(
        store: HealthStoreProtocol,
        categoryType: HKCategoryType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKCategorySample] {
        let samples = try await HKQueryAsync.samples(
            store: store,
            sampleType: categoryType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
        return samples.compactMap { $0 as? HKCategorySample }
    }

    static func quantitySamples(
        store: HealthStoreProtocol,
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKQuantitySample] {
        let samples = try await HKQueryAsync.samples(
            store: store,
            sampleType: quantityType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
        return samples.compactMap { $0 as? HKQuantitySample }
    }
}
