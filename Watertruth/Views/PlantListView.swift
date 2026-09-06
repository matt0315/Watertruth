import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementService
    @Query(filter: #Predicate<Plant> { !$0.isArchived }, sort: \Plant.nickname)
    private var plants: [Plant]

    @State private var showAdd = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView {
                        Label("No plants yet", systemImage: "leaf")
                    } description: {
                        Text("Add a plant to get soil-check reminders. \(AppConstants.trustTagline)")
                    } actions: {
                        Button("Add plant") { attemptAdd() }
                            .buttonStyle(.borderedProminent)
                            .tint(WatertruthTheme.leaf)
                    }
                } else {
                    List {
                        if !entitlements.effectiveIsPro {
                            Section {
                                Text("Free: reminders for \(min(plants.count, entitlements.freePlantLimit)) of \(entitlements.freePlantLimit) plants.")
                                    .font(.caption)
                                    .foregroundStyle(WatertruthTheme.muted)
                            }
                        }
                        ForEach(plants) { plant in
                            NavigationLink {
                                PlantDetailView(plant: plant)
                            } label: {
                                HStack(spacing: 12) {
                                    PlantPhotoThumbnail(data: plant.photoData, size: 52, cornerRadius: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(plant.nickname)
                                            .font(.headline)
                                        Text("\(plant.speciesTag.isEmpty ? "Houseplant" : plant.speciesTag) · \(plant.roomZone)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let who = plant.whoWateredLabel {
                                            Text(who)
                                                .font(.caption2)
                                                .foregroundStyle(WatertruthTheme.earth)
                                        }
                                    }
                                    Spacer()
                                    if plant.isDueToday {
                                        Text("Check")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(WatertruthTheme.leaf)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Plants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add plant")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddPlantView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func attemptAdd() {
        if entitlements.canAddPlant(currentCount: plants.count) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let plant = plants[index]
            Task { await NotificationService.shared.cancel(for: plant.id) }
            modelContext.delete(plant)
        }
        WidgetDataWriter.write(plants: Array(plants))
    }
}
