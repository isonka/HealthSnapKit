import Foundation
import HealthKit

/// Fetches the most recent body mass, BMI, and body fat percentage samples.
@MainActor
public final class BodyProvider {
    private let store: HealthStoreProtocol

    /// Creates a provider that reads from the given HealthKit store abstraction.
    public init(store: HealthStoreProtocol) {
        self.store = store
    }

    /// Returns the latest body metrics as of now (same as ``latest()``).
    public func today() async throws -> BodySnapshot {
        try await latest(asOf: Date())
    }

    /// Returns the latest body metrics recorded on or before the end of the calendar day containing `date`.
    public func date(_ date: Date) async throws -> BodySnapshot {
        let cal = Calendar.current
        guard let endExclusive = CalendarDayRange.exclusiveEndOfDay(containing: date, calendar: cal) else {
            throw HealthSnapError.noData
        }
        return try await latest(asOf: endExclusive)
    }

    /// Returns one ``BodySnapshot`` per calendar day in `range`, using metrics available at each day’s end.
    public func range(_ range: ClosedRange<Date>) async throws -> [BodySnapshot] {
        let cal = Calendar.current
        let start = CalendarDayRange.startOfDay(range.lowerBound, calendar: cal)
        let endDay = CalendarDayRange.startOfDay(range.upperBound, calendar: cal)
        var days: [Date] = []
        var d = start
        while d <= endDay {
            days.append(d)
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        var out: [BodySnapshot] = []
        for day in days {
            out.append(try await date(day))
        }
        return out
    }

    /// Returns body snapshots for the last `n` calendar days ending today (inclusive).
    public func last(days n: Int) async throws -> [BodySnapshot] {
        guard n > 0 else { throw HealthSnapError.noData }
        let cal = Calendar.current
        guard let interval = CalendarDayRange.lastDaysInterval(n, endingAt: Date(), calendar: cal) else {
            throw HealthSnapError.noData
        }
        let upper = interval.endExclusive.addingTimeInterval(-1)
        return try await range(interval.start...upper)
    }

    /// Returns the newest available weight, BMI, and body fat samples at or before `asOf`.
    public func latest() async throws -> BodySnapshot {
        try await latest(asOf: Date())
    }

    private func latest(asOf end: Date) async throws -> BodySnapshot {
        guard store.isHealthDataAvailable() else { throw HealthSnapError.notAvailable }
        let weight = try await latestSample(identifier: .bodyMass, asOf: end, unit: HKUnit.gramUnit(with: .kilo))
        let bmi = try await latestSample(identifier: .bodyMassIndex, asOf: end, unit: HKUnit.count())
        let fat = try await latestSample(identifier: .bodyFatPercentage, asOf: end, unit: HKUnit.percent())
        if weight == nil, bmi == nil, fat == nil {
            throw HealthSnapError.noData
        }
        let dates = [weight?.date, bmi?.date, fat?.date].compactMap { $0 }
        let anchor = dates.max() ?? end
        return BodySnapshot(
            date: anchor,
            weightKg: weight?.value,
            bmi: bmi?.value,
            bodyFatPercentage: fat?.value
        )
    }

    private func latestSample(
        identifier: HKQuantityTypeIdentifier,
        asOf end: Date,
        unit: HKUnit
    ) async throws -> (date: Date, value: Double)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: end, options: .strictEndDate)
        let samples = try await store.samples(
            sampleType: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ).compactMap { $0 as? HKQuantitySample }
        guard let sample = samples.first else { return nil }
        return (sample.startDate, sample.quantity.doubleValue(for: unit))
    }
}
