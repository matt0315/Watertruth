import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var plant: Plant
    @State private var showSoilCheck = false
    @State private var showJournal = false
    @State private var fertilizeOn: Bool = false
    @State private var repotOn: Bool = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plant.nickname)
                        .font(.largeTitle.weight(.bold))
                    if !plant.speciesTag.isEmpty {
                        Text(plant.speciesTag)
                            .foregroundStyle(WatertruthTheme.muted)
                    }
                    Label(plant.roomZone, systemImage: "door.left.hand.open")
                        .font(.subheadline)
                    Text(plant.learnedNextLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WatertruthTheme.leaf)
                    if let who = plant.whoWateredLabel {
                        Text("Last watered: \(who)")
                            .font(.caption)
                            .foregroundStyle(WatertruthTheme.earth)
                            .accessibilityLabel("Last watered by \(who)")
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Care") {
                Button {
                    showSoilCheck = true
                } label: {
                    Label("Check soil now", systemImage: "hand.point.up.left.fill")
                }
                .accessibilityLabel("Check soil for \(plant.nickname)")

                NavigationLink {
                    ManualOverrideView(plant: plant)
                } label: {
                    Label("Schedule & override", systemImage: "calendar")
                }

                Button {
                    showJournal = true
                } label: {
                    Label("Photo journal", systemImage: "photo.on.rectangle")
                }
            }

            Section("Secondary reminders") {
                Toggle("Fertilize reminders", isOn: Binding(
                    get: { plant.fertilizeEnabled },
                    set: { newValue in
                        plant.fertilizeEnabled = newValue
                        if newValue && plant.nextFertilizeAt == nil {
                            plant.nextFertilizeAt = Calendar.current.date(byAdding: .day, value: plant.fertilizeIntervalDays, to: Date())
                        }
                    }
                ))
                if plant.fertilizeEnabled {
                    Stepper("Every \(plant.fertilizeIntervalDays) days", value: $plant.fertilizeIntervalDays, in: 14...90)
                }
                Toggle("Repot reminders", isOn: Binding(
                    get: { plant.repotEnabled },
                    set: { newValue in
                        plant.repotEnabled = newValue
                        if newValue && plant.nextRepotAt == nil {
                            plant.nextRepotAt = Calendar.current.date(byAdding: .day, value: plant.repotIntervalDays, to: Date())
                        }
                    }
                ))
                if plant.repotEnabled {
                    Stepper("Every \(plant.repotIntervalDays) days", value: $plant.repotIntervalDays, in: 90...730)
                }
                Text("Simple intervals only — no disease or pest engine.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Details") {
                LabeledContent("Pot", value: plant.potSize)
                LabeledContent("Medium", value: plant.medium)
                LabeledContent("Light", value: plant.lightNote)
                LabeledContent("Location", value: plant.isOutdoor ? "Outdoor" : "Indoor")
                LabeledContent("Mode", value: plant.scheduleMode.displayName)
            }

            Section("Recent care") {
                let recent = plant.careEvents.sorted { $0.timestamp > $1.timestamp }.prefix(8)
                if recent.isEmpty {
                    Text("No care events yet. Start with a soil check.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recent), id: \.id) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(event.kind.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(event.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(event.performedBy)
                                .font(.caption)
                                .foregroundStyle(WatertruthTheme.earth)
                            if let m = event.soilMoisture {
                                Text("Soil: \(m.displayName)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }

            Section {
                TrustBanner()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Plant")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSoilCheck) {
            SoilCheckFlowView(plant: plant)
        }
        .sheet(isPresented: $showJournal) {
            JournalView(plant: plant)
        }
    }
}
