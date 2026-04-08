import Foundation
import HealthKit

/// Logical domains of HealthKit data that can be requested for read access.
public enum HealthDataDomain: String, Sendable, Codable, CaseIterable {
    /// Step count, energy, distance, exercise time, and stand hours.
    case activity
    /// Sleep analysis categories (including stage breakdown where available).
    case sleep
    /// Heart rate, resting heart rate, and heart rate variability (SDNN).
    case heart
    /// Weight, BMI, and body fat percentage.
    case body
}

/// Maps ``HealthDataDomain`` values to concrete HealthKit object types for authorization.
public enum HealthKitPermissions: Sendable {
    /// All sample and object types required to read data for the given domains.
    public static func objectTypes(for domains: Set<HealthDataDomain>) -> Set<HKObjectType> {
        var types = Set<HKObjectType>()
        for domain in domains {
            switch domain {
            case .activity:
                types.formUnion(activityReadTypes())
            case .sleep:
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    types.insert(sleepType)
                }
            case .heart:
                types.formUnion(heartReadTypes())
            case .body:
                types.formUnion(bodyReadTypes())
            }
        }
        return types
    }

    private static func activityReadTypes() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()
        if let t = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .appleStandHour) { set.insert(t) }
        return set
    }

    private static func heartReadTypes() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()
        if let t = HKObjectType.quantityType(forIdentifier: .heartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { set.insert(t) }
        return set
    }

    private static func bodyReadTypes() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMass) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) { set.insert(t) }
        return set
    }
}
