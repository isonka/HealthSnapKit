import Foundation
import HealthKit
import XCTest
@testable import HealthSnapKit

final class HeartProviderTests: XCTestCase {
    @MainActor
    func testMapsQuantitySamplesToSnapshot() async throws {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            XCTFail("Missing heart rate type")
            return
        }
        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let day = Date(timeIntervalSince1970: 1_704_067_200)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let interval = CalendarDayRange.dayInterval(containing: day, calendar: cal) else {
            XCTFail("Missing interval")
            return
        }
        let s1 = HKQuantitySample(
            type: hrType,
            quantity: HKQuantity(unit: bpmUnit, doubleValue: 60),
            start: interval.start.addingTimeInterval(3600),
            end: interval.start.addingTimeInterval(3600)
        )
        let s2 = HKQuantitySample(
            type: hrType,
            quantity: HKQuantity(unit: bpmUnit, doubleValue: 80),
            start: interval.start.addingTimeInterval(7200),
            end: interval.start.addingTimeInterval(7200)
        )

        let mock = MockHealthStore()
        mock.statisticsImpl = { _, _, _ in nil }
        mock.samplesImpl = { sampleType, _, _, _ in
            if sampleType == hrType {
                return [s1, s2]
            }
            return []
        }

        let provider = HeartProvider(store: mock)
        let snap = try await provider.date(day)
        XCTAssertEqual(snap.samples.count, 2)
        XCTAssertEqual(snap.averageBPM, 70, accuracy: 0.001)
        XCTAssertEqual(snap.samples[0].bpm, 60, accuracy: 0.001)
        XCTAssertEqual(snap.samples[1].bpm, 80, accuracy: 0.001)
    }

    @MainActor
    func testThrowsNoDataWhenEmpty() async throws {
        let mock = MockHealthStore()
        mock.statisticsImpl = { _, _, _ in nil }
        mock.samplesImpl = { _, _, _, _ in [] }
        let provider = HeartProvider(store: mock)
        do {
            _ = try await provider.today()
            XCTFail("Expected noData")
        } catch let e as HealthSnapError {
            if case .noData = e {
                // expected
            } else {
                XCTFail("wrong error: \(e)")
            }
        }
    }
}
