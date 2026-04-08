import Foundation
import HealthKit

/// Fetches sleep stage summaries grouped into nights.
public final class SleepProvider {
    private let store: HealthStoreProtocol

    /// Creates a provider that reads from the given HealthKit store abstraction.
    public init(store: HealthStoreProtocol) {
        self.store = store
    }

    /// Fetches a ``SleepSnapshot`` for the night attributed to the calendar day of `date`.
    public func today() async throws -> SleepSnapshot {
        try await date(Date())
    }

    /// Fetches a ``SleepSnapshot`` for the calendar day containing `date`.
    public func date(_ date: Date) async throws -> SleepSnapshot {
        let cal = Calendar.current
        guard let interval = CalendarDayRange.dayInterval(containing: date, calendar: cal) else {
            throw HealthSnapError.noData
        }
        guard let windowStart = cal.date(byAdding: .hour, value: -20, to: interval.start) else {
            throw HealthSnapError.noData
        }
        let upper = interval.endExclusive.addingTimeInterval(-1)
        let list = try await range(windowStart...upper)
        let targetStart = CalendarDayRange.startOfDay(date, calendar: cal)
        guard let match = list.last(where: { cal.isDate($0.date, inSameDayAs: targetStart) }) else {
            throw HealthSnapError.noData
        }
        return match
    }

    /// Fetches sleep snapshots for each detected night overlapping `range`.
    public func range(_ range: ClosedRange<Date>) async throws -> [SleepSnapshot] {
        guard store.isHealthDataAvailable() else { throw HealthSnapError.notAvailable }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthSnapError.noData
        }
        let cal = Calendar.current
        let start = CalendarDayRange.startOfDay(range.lowerBound, calendar: cal)
        guard let endExclusive = CalendarDayRange.exclusiveEndOfDay(containing: range.upperBound, calendar: cal) else {
            throw HealthSnapError.noData
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: endExclusive, options: .strictStartDate)
        let raw = try await store.samples(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        )
        let samples = raw.compactMap { $0 as? HKCategorySample }
        if samples.isEmpty {
            throw HealthSnapError.noData
        }
        return SleepAnalysisAggregator.snapshots(from: samples, calendar: cal)
    }

    /// Fetches up to the last `n` nights ending near today.
    public func last(nights n: Int) async throws -> [SleepSnapshot] {
        guard n > 0 else { throw HealthSnapError.noData }
        let cal = Calendar.current
        guard let interval = CalendarDayRange.lastNightsInterval(n, endingAt: Date(), calendar: cal) else {
            throw HealthSnapError.noData
        }
        let upper = interval.endExclusive.addingTimeInterval(-1)
        let all = try await range(interval.start...upper)
        return Array(all.suffix(n))
    }
}
