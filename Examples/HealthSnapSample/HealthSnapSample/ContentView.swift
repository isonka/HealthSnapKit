import HealthSnapKit
import SwiftUI

@MainActor
struct ContentView: View {
    private enum DataMode: String, CaseIterable, Identifiable, Hashable {
        case live = "HealthKit"
        case mock = "Mock"
        var id: String { rawValue }
    }

    @State private var dataMode: DataMode = .live
    @State private var kit = HealthSnapKit()
    @State private var status = "Choose HealthKit or Mock, then load."
    @State private var activityText = "—"
    @State private var heartText = "—"
    @State private var sleepText = "—"
    @State private var bodyText = "—"
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            List {
                Section("Data source") {
                    Picker("Source", selection: $dataMode) {
                        ForEach(DataMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("dataSourcePicker")
                }
                Section("Setup") {
                    Button("Request Health access") {
                        Task { await authorize() }
                    }
                    .disabled(isBusy || dataMode == .mock)
                    if dataMode == .mock {
                        Text("Mock mode skips HealthKit. Tap Load samples for demo values.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
            .onChange(of: dataMode) { _, newValue in
                switch newValue {
                case .live:
                    resetRows()
                    status = "HealthKit mode: request access, then load."
                case .mock:
                    resetRows()
                    status = "Mock mode: tap Load samples for static demo data."
                }
            }
        }
    }

    private func resetRows() {
        activityText = "—"
        heartText = "—"
        sleepText = "—"
        bodyText = "—"
    }

    private func authorize() async {
        guard dataMode == .live else { return }
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

        switch dataMode {
        case .mock:
            applyMockSnapshots()
            status = "Mock data · \(Date().formatted(date: .omitted, time: .shortened)) · no HealthKit calls"
        case .live:
            await loadActivity()
            await loadHeart()
            await loadSleep()
            await loadBody()
            status = "Updated \(Date().formatted(date: .omitted, time: .shortened)). Each section loads independently."
        }
    }

    private func applyMockSnapshots() {
        let now = Date()
        activityText = SampleSnapshotFormatting.activity(DemoSnapshots.makeActivity(referenceNow: now))
        heartText = SampleSnapshotFormatting.heart(DemoSnapshots.makeHeart(referenceNow: now))
        sleepText = SampleSnapshotFormatting.sleepLatestNight(DemoSnapshots.makeSleepNights(referenceNow: now))
        bodyText = SampleSnapshotFormatting.body(DemoSnapshots.makeBody(referenceNow: now))
    }

    private func loadActivity() async {
        do {
            let activity = try await kit.activity.today()
            activityText = SampleSnapshotFormatting.activity(activity)
        } catch {
            activityText = describe(error)
        }
    }

    private func loadHeart() async {
        do {
            let heart = try await kit.heart.today()
            heartText = SampleSnapshotFormatting.heart(heart)
        } catch {
            heartText = describe(error)
        }
    }

    private func loadSleep() async {
        do {
            let sleepNights = try await kit.sleep.last(nights: 3)
            sleepText = SampleSnapshotFormatting.sleepLatestNight(sleepNights)
        } catch {
            sleepText = describe(error)
        }
    }

    private func loadBody() async {
        do {
            let body = try await kit.body.latest()
            bodyText = SampleSnapshotFormatting.body(body)
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
