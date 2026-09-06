import SwiftUI
import SwiftData

/// Soil-check sheet: dry / moist / wet → water or snooze; recalculates next due.
/// Optional progress photo attaches to the CareEvent (not AI diagnosis).
struct SoilCheckFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var shareService: ShareService

    @Bindable var plant: Plant
    @State private var selected: SoilMoisture?
    @State private var engine = ScheduleEngine()
    @State private var resultMessage: String?
    @State private var progressPhotoData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How does the soil feel?")
                        .font(.title2.weight(.semibold))
                    Text(AppConstants.trustTagline)
                        .font(.subheadline)
                        .foregroundStyle(WatertruthTheme.muted)

                    ForEach(SoilMoisture.allCases) { moisture in
                        Button {
                            selected = moisture
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: moisture.systemImage)
                                    .font(.title2)
                                    .foregroundStyle(WatertruthTheme.leaf)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(moisture.displayName)
                                        .font(.headline)
                                        .foregroundStyle(WatertruthTheme.ink)
                                    Text(moisture.guidance)
                                        .font(.caption)
                                        .foregroundStyle(WatertruthTheme.muted)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                if selected == moisture {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(WatertruthTheme.leaf)
                                }
                            }
                            .padding()
                            .background(selected == moisture ? WatertruthTheme.sand : WatertruthTheme.clay.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(moisture.displayName). \(moisture.guidance)")
                    }

                    if selected != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress photo (optional)")
                                .font(.subheadline.weight(.semibold))
                            Text("Snap growth over time — you judge better/same/worse later. No plant-ID or disease scan.")
                                .font(.caption)
                                .foregroundStyle(WatertruthTheme.muted)
                            PlantPhotoPickerRow(
                                photoData: $progressPhotoData,
                                title: "Attach to this check",
                                allowRemove: true
                            )
                        }
                        .padding()
                        .background(WatertruthTheme.sand.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let selected {
                        actionButtons(for: selected)
                    }

                    if let resultMessage {
                        Text(resultMessage)
                            .font(.subheadline)
                            .foregroundStyle(WatertruthTheme.leaf)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationTitle(plant.nickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.large, .medium])
    }

    @ViewBuilder
    private func actionButtons(for moisture: SoilMoisture) -> some View {
        switch moisture {
        case .dry:
            Button {
                commit(moisture: .dry, waterIfDry: true)
            } label: {
                Label("Soil is dry — water & log", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(WatertruthTheme.leaf)
            .accessibilityLabel("Confirm dry soil and water \(plant.nickname)")

            Button("Dry but skip watering") {
                commit(moisture: .dry, waterIfDry: false)
            }
            .accessibilityLabel("Mark soil dry but do not water")
        case .moist, .wet:
            Button {
                commit(moisture: moisture, waterIfDry: false)
            } label: {
                Label("Snooze check", systemImage: "moon.zzz")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(WatertruthTheme.earth)
            .accessibilityLabel("Snooze because soil is \(moisture.displayName)")
        }
    }

    private func commit(moisture: SoilMoisture, waterIfDry: Bool) {
        let by = shareService.currentCaretakerName()
        let event = engine.applySoilCheck(to: plant, moisture: moisture, performedBy: by, waterIfDry: waterIfDry)
        event.photoData = progressPhotoData
        try? modelContext.save()
        NotificationService.shared.clearDelivered(for: plant.id)
        Task {
            await NotificationService.shared.scheduleSoilCheck(
                for: plant.id,
                plantName: plant.nickname,
                at: plant.nextDueAt
            )
        }
        resultMessage = plant.learnedNextLabel + (event.didWaterLabel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }
}

private extension CareEvent {
    var didWaterLabel: String {
        kind == .watered ? " · Logged watering" : " · Check snoozed"
    }
}
