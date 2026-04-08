import Foundation
import HealthKit

/// Default ``HealthStoreProtocol`` implementation backed by ``HKHealthStore``.
public final class LiveHealthStore: HealthStoreProtocol {
    private let store: HKHealthStore

    /// Creates a store that wraps the shared HealthKit store.
    public init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    public func isHealthDataAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public func requestAuthorization(
        toShare: Set<HKSampleType>,
        read: Set<HKObjectType>,
        completion: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        store.requestAuthorization(toShare: toShare, read: read, completion: completion)
    }

    public func statisticsCollection(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) async throws -> HKStatisticsCollection {
        try await HKQueryAsync.statisticsCollection(
            store: store,
            quantityType: quantityType,
            predicate: predicate,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
    }

    public func statistics(
        quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await HKQueryAsync.statistics(
            store: store,
            quantityType: quantityType,
            predicate: predicate,
            options: options
        )
    }

    public func samples(
        sampleType: HKSampleType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKSample] {
        try await HKQueryAsync.samples(
            store: store,
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
    }
}
