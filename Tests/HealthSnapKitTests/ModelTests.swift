import Foundation
import HealthKit
import XCTest
@testable import HealthSnapKit

final class ModelTests: XCTestCase {
    func testActivitySnapshotCodableRoundTrip() throws {
        let original = ActivitySnapshot(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            steps: 8_432,
            activeCalories: 420.5,
            totalCalories: 2_100,
            distanceMeters: 6_000,
            exerciseMinutes: 45,
            standHours: 10
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ActivitySnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testSleepSnapshotCodableRoundTrip() throws {
        let stages = SleepStages(awake: 600, rem: 3_600, core: 14_400, deep: 7_200)
        let original = SleepSnapshot(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            totalDuration: 25_800,
            efficiency: 0.88,
            stages: stages
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SleepSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testHeartSnapshotCodableRoundTrip() throws {
        let samples = [HeartSample(timestamp: Date(timeIntervalSince1970: 1), bpm: 72)]
        let original = HeartSnapshot(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            averageBPM: 68,
            restingBPM: 55,
            hrvSDNN: 42,
            samples: samples
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HeartSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testBodySnapshotCodableRoundTrip() throws {
        let original = BodySnapshot(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            weightKg: 70.5,
            bmi: 22.1,
            bodyFatPercentage: 18
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BodySnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testLastDaysIntervalSpansNDays() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        // 2023-12-31 00:00:00 UTC — last 3 calendar days are Dec 29, 30, 31.
        let end = Date(timeIntervalSince1970: 1_703_980_800)
        let interval = CalendarDayRange.lastDaysInterval(3, endingAt: end, calendar: cal)
        XCTAssertNotNil(interval)
        guard let interval else { return }
        XCTAssertEqual(interval.start, Date(timeIntervalSince1970: 1_703_808_000)) // 2023-12-29 00:00 UTC
        XCTAssertEqual(interval.endExclusive, Date(timeIntervalSince1970: 1_704_067_200)) // 2024-01-01 00:00 UTC
    }

    func testLastNightsIntervalCoversExpectedWindow() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let end = Date(timeIntervalSince1970: 1_703_980_800) // 2023-12-31 00:00 UTC
        let interval = CalendarDayRange.lastNightsInterval(7, endingAt: end, calendar: cal)
        XCTAssertNotNil(interval)
        guard let interval else { return }
        XCTAssertEqual(interval.endExclusive, Date(timeIntervalSince1970: 1_704_067_200)) // 2024-01-01 00:00 UTC
    }
}
