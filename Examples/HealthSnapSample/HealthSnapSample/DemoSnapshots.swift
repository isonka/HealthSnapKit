import Foundation
import HealthSnapKit

/// Static ``ActivitySnapshot`` / ``HeartSnapshot`` / etc. for simulator and UI demos without HealthKit data.
enum DemoSnapshots {
    static func makeActivity(referenceNow: Date = .init()) -> ActivitySnapshot {
        let day = Calendar.current.startOfDay(for: referenceNow)
        return ActivitySnapshot(
            date: day,
            steps: 10_247,
            activeCalories: 412,
            totalCalories: 2180,
            distanceMeters: 7820,
            exerciseMinutes: 48,
            standHours: 11
        )
    }

    static func makeHeart(referenceNow: Date = .init()) -> HeartSnapshot {
        let day = Calendar.current.startOfDay(for: referenceNow)
        let base = day.addingTimeInterval(8 * 3600)
        let samples = [
            HeartSample(timestamp: base, bpm: 62),
            HeartSample(timestamp: base.addingTimeInterval(3600), bpm: 74),
            HeartSample(timestamp: base.addingTimeInterval(7200), bpm: 88),
            HeartSample(timestamp: base.addingTimeInterval(10_800), bpm: 71),
        ]
        return HeartSnapshot(
            date: day,
            averageBPM: 73.75,
            restingBPM: 58,
            hrvSDNN: 44.2,
            samples: samples
        )
    }

    /// Three synthetic nights ending on the calendar day of `referenceNow`.
    static func makeSleepNights(referenceNow: Date = .init()) -> [SleepSnapshot] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: referenceNow)
        var nights: [SleepSnapshot] = []
        for offset in (0 ..< 3).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let s = SleepStages(
                awake: 25 * 60 + Double(offset) * 60,
                rem: 1.75 * 3600,
                core: 3.5 * 3600,
                deep: 1.25 * 3600
            )
            let a = s.rem + s.core + s.deep
            let ib = a + s.awake
            nights.append(SleepSnapshot(
                date: day,
                totalDuration: a,
                efficiency: ib > 0 ? a / ib : 0,
                stages: s
            ))
        }
        return nights
    }

    static func makeBody(referenceNow: Date = .init()) -> BodySnapshot {
        BodySnapshot(
            date: referenceNow.addingTimeInterval(-3600),
            weightKg: 70.4,
            bmi: 22.3,
            bodyFatPercentage: 19.5
        )
    }
}
