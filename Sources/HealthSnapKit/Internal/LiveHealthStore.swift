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

    public func execute(_ query: HKQuery) {
        store.execute(query)
    }
}
