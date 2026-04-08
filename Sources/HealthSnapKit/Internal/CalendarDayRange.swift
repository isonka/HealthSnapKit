import Foundation

/// Calendar boundaries for day-based HealthKit queries.
enum CalendarDayRange {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Exclusive end of the calendar day containing `date` (start of the following day).
    static func exclusiveEndOfDay(containing date: Date, calendar: Calendar = .current) -> Date? {
        let start = startOfDay(date, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: start)
    }

    /// Predicate-friendly inclusive start and exclusive end for the calendar day of `date`.
    static func dayInterval(containing date: Date, calendar: Calendar = .current) -> (start: Date, endExclusive: Date)? {
        let start = startOfDay(date, calendar: calendar)
        guard let endExclusive = exclusiveEndOfDay(containing: date, calendar: calendar) else { return nil }
        return (start, endExclusive)
    }

    /// Last `n` calendar days ending on the day of `end` (inclusive), as `(firstStart, lastEndExclusive)`.
    static func lastDaysInterval(_ n: Int, endingAt end: Date, calendar: Calendar = .current) -> (start: Date, endExclusive: Date)? {
        guard n > 0 else { return nil }
        guard let lastEndExclusive = exclusiveEndOfDay(containing: end, calendar: calendar) else { return nil }
        let lastStart = startOfDay(end, calendar: calendar)
        guard let firstStart = calendar.date(byAdding: .day, value: -(n - 1), to: lastStart) else { return nil }
        return (firstStart, lastEndExclusive)
    }

    /// Query window for roughly `n` nights of sleep ending near `end`.
    static func lastNightsInterval(_ n: Int, endingAt end: Date, calendar: Calendar = .current) -> (start: Date, endExclusive: Date)? {
        guard n > 0 else { return nil }
        guard let endExclusive = exclusiveEndOfDay(containing: end, calendar: calendar) else { return nil }
        let anchor = startOfDay(end, calendar: calendar)
        guard let start = calendar.date(byAdding: .day, value: -n, to: anchor) else { return nil }
        return (start, endExclusive)
    }
}
