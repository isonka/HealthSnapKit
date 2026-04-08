import Foundation
import HealthKit
import XCTest
@testable import HealthSnapKit

final class ActivityProviderTests: XCTestCase {
    @MainActor
    func testTodayThrowsNoDataWhenMockReturnsNoStatisticsOrSamples() async throws {
        let mock = MockHealthStore()
        mock.statisticsImpl = { _, _, _ in nil }
        mock.samplesImpl = { _, _, _, _ in [] }
        let provider = ActivityProvider(store: mock)
        do {
            _ = try await provider.today()
            XCTFail("Expected HealthSnapError.noData")
        } catch let error as HealthSnapError {
            if case .noData = error {
                // expected
            } else {
                XCTFail("Unexpected error \(error)")
            }
        }
    }
}
