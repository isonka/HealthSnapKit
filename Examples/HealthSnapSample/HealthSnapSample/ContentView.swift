import HealthSnapKit
import SwiftUI

@MainActor
struct ContentView: View {
    @State private var kit = HealthSnapKit()
    @State private var status = "Tap Authorize, then Load data."
    @State private var activityText = "—"
    @State private var heartText = "—"
    @State private var sleepText = "—"
    @State private var bodyText = "—"
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            List {
                Section("Setup") {
                    Button("Request Health access") {
                        Task { await authorize() }
                    }
                    .disabled(isBusy)
                }
                Section("Fetch (today / latest)") {
                    Button("Load samples") {
                        Task { await loadAll() }
                    }
                    .disabled(isBusy)
                }
                Section("Activity") {
                    Text(activityText)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Section("Heart") {
                    Text(heartText)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Section("Sleep") {
                    Text(sleepText)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Section("Body") {
                    Text(bodyText)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("HealthSnapKit")
            .overlay {
                if isBusy {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    private func authorize() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await kit.requestAuthorization()
            status = "Authorization completed. Tap Load samples. (If a category is empty, Health may have no data for today—not always a permission issue.)"
        } catch {
            status = "Auth error: \(describe(error))"
        }
    }

    private func loadAll() async {
        isBusy = true
        defer { isBusy = false }

        await loadActivity()
        await loadHeart()
        await loadSleep()
        await loadBody()

        status = "Updated \(Date().formatted(date: .omitted, time: .shortened)). Each section loads independently."
    }

    private func loadActivity() async {
        do {
            let activity = try await kit.activity.today()
            activityText = "Steps: \(activity.steps) · Active kcal: \(Int(activity.activeCalories)) · Distance km: \(String(format: "%.2f", activity.distanceMeters / 1000))"
        } catch {
            activityText = describe(error)
        }
    }

    private func loadHeart() async {
        do {
            let heart = try await kit.heart.today()
            heartText = "Avg BPM: \(String(format: "%.0f", heart.averageBPM)) · Resting: \(heart.restingBPM.map { String(format: "%.0f", $0) } ?? "—") · HRV SDNN ms: \(heart.hrvSDNN.map { String(format: "%.1f", $0) } ?? "—") · Samples: \(heart.samples.count)"
        } catch {
            heartText = describe(error)
        }
    }

    private func loadSleep() async {
        do {
            let sleepNights = try await kit.sleep.last(nights: 3)
            if let last = sleepNights.last {
                let hours = last.totalDuration / 3600
                let dayLabel = last.date.formatted(date: .abbreviated, time: .omitted)
                sleepText = "Latest night (\(dayLabel)): \(hours.formatted(.number.precision(.fractionLength(1)))) h asleep · efficiency \(String(format: "%.0f%%", last.efficiency * 100)) · nights: \(sleepNights.count)"
            } else {
                sleepText = "No sleep sessions in the last few nights."
            }
        } catch {
            sleepText = describe(error)
        }
    }

    private func loadBody() async {
        do {
            let body = try await kit.body.latest()
            bodyText = "Weight kg: \(body.weightKg.map { String(format: "%.1f", $0) } ?? "—") · BMI: \(body.bmi.map { String(format: "%.1f", $0) } ?? "—") · Body fat %: \(body.bodyFatPercentage.map { String(format: "%.1f", $0) } ?? "—")"
        } catch {
            bodyText = describe(error)
        }
    }

    private func describe(_ error: Error) -> String {
        if let le = error as? LocalizedError, let d = le.errorDescription {
            return d
        }
        return error.localizedDescription
    }
}

#Preview {
    ContentView()
}
