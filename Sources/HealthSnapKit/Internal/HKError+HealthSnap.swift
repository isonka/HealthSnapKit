import Foundation
import HealthKit

extension HKError {
    /// HealthKit uses this when a predicate matches no samples; callers should treat it as empty data, not a hard failure.
    static func isNoMatchingSamples(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == HKError.errorDomain && ns.code == HKError.Code.errorNoData.rawValue
    }
}
