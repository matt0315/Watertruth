import SwiftUI
import SwiftData

/// Always-on manual “every N days” — never lock users into opaque AI.
struct ManualOverrideView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    @State private var days: Int
    @State private var useAdaptive: Bool
    @State private var engine = ScheduleEngine()

    init(plant: Plant) {
        self.plant = plant
        _days = State(initialValue: Int(plant.intervalDays.rounded()))
        _useAdaptive = State(initialValue: plant.scheduleMode == .adaptive)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Adaptive (learns from early/late/snooze)", isOn: $useAdaptive)
                if !useAdaptive {
                    Stepper("Every \(days) days", value: $days, in: 1...45)
                    Text("We’ll remind you to check soil every \(days) days. You can switch back to adaptive anytime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Interval starts at \(Int(plant.intervalDays.rounded())) days and shifts when you water early/late or snooze wet soil.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Watering schedule")
            } footer: {
                Text(AppConstants.trustTagline)
            }

            Section {
                Button("Save") {
                    if useAdaptive {
                        let result = engine.switchToAdaptive(currentInterval: Double(days))
                        plant.scheduleMode = result.mode
                        plant.intervalDays = result.intervalDays
                        plant.updatedAt = Date()
                    } else {
                        engine.applyManualOverride(to: plant, everyDays: days)
                    }
                    Task {
                        await NotificationService.shared.scheduleSoilCheck(
                            for: plant.id,
                            plantName: plant.nickname,
                            at: plant.nextDueAt
                        )
                    }
                    dismiss()
                }
                .accessibilityLabel("Save schedule override")
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}
