import Foundation
import HealthKit
import XCTest
@testable import HealthSnapKit

final class SleepProviderTests: XCTestCase {
    @MainActor
    func testRangeThrowsNoDataWhenSamplesEmpty() async throws {
        let mock = MockHealthStore()
        mock.samplesImpl = { _, _, _, _ in [] }
        let provider = SleepProvider(store: mock)
        let start = Date(timeIntervalSince1970: 1_704_067_200)
        let end = start.addingTimeInterval(86_400)
        do {
            _ = try await provider.range(start...end)
            XCTFail("Expected noData")
        } catch let e as HealthSnapError {
            if case .noData = e {
                // expected
            } else {
                XCTFail("wrong error: \(e)")
            }
        }
    }

    @MainActor
    func testMapsCategorySamplesToSnapshot() async throws {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            XCTFail("Missing sleep type")
            return
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = cal.startOfDay(for: Date(timeIntervalSince1970: 1_704_067_200))
        let start = anchor.addingTimeInterval(-4 * 3600)
        let mid = start.addingTimeInterval(4 * 3600)
        let end = mid.addingTimeInterval(4 * 3600)

        let inBed = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: start,
            end: end
        )
        let deep = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            start: start,
            end: mid
        )

        let mock = MockHealthStore()
        mock.samplesImpl = { sampleType, _, _, _ in
            if sampleType == sleepType {
                return [inBed, deep]
            }
            return []
        }

        let provider = SleepProvider(store: mock)
        let list = try await provider.range(start...end)
        XCTAssertFalse(list.isEmpty)
        let snap = list[0]
        XCTAssertGreaterThan(snap.totalDuration, 0)
        XCTAssertGreaterThan(snap.stages.deep, 0)
    }
}
