import Foundation
import HealthKit
import XCTest
@testable import HealthSnapKit

final class BodyProviderTests: XCTestCase {
    func testLatestThrowsNoDataWhenEmpty() async throws {
        let mock = MockHealthStore()
        mock.samplesImpl = { _, _, _, _ in [] }
        let provider = BodyProvider(store: mock)
        do {
            _ = try await provider.latest()
            XCTFail("Expected noData")
        } catch let e as HealthSnapError {
            if case .noData = e {
                // expected
            } else {
                XCTFail("wrong error: \(e)")
            }
        }
    }

    func testMapsWeightSample() async throws {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            XCTFail("Missing type")
            return
        }
        let kg = HKUnit.gramUnit(with: .kilo)
        let sample = HKQuantitySample(
            type: massType,
            quantity: HKQuantity(unit: kg, doubleValue: 72.4),
            start: Date(timeIntervalSince1970: 1_704_067_200),
            end: Date(timeIntervalSince1970: 1_704_067_200)
        )
        let mock = MockHealthStore()
        mock.samplesImpl = { sampleType, _, limit, _ in
            if sampleType == massType, limit == 1 {
                return [sample]
            }
            return []
        }
        let provider = BodyProvider(store: mock)
        let snap = try await provider.latest()
        XCTAssertEqual(snap.weightKg ?? 0, 72.4, accuracy: 0.01)
    }
}
