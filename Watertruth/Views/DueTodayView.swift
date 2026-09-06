import SwiftUI
import SwiftData

struct DueTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var shareService: ShareService
    @Query(filter: #Predicate<Plant> { !$0.isArchived }, sort: \Plant.nextDueAt)
    private var plants: [Plant]

    @State private var roomFilter: String = "All"
    @State private var soilCheckPlant: Plant?
    @State private var engine = ScheduleEngine()

    private var rooms: [String] {
        let zones = Set(plants.map(\.roomZone)).sorted()
        return ["All"] + zones
    }

    private var filteredDue: [Plant] {
        let due = plants.filter(\.isDueToday)
        if roomFilter == "All" { return due }
        return due.filter { $0.roomZone == roomFilter }
    }

    private var fertilizeDue: [Plant] {
        let due = plants.filter(\.isFertilizeDueToday)
        if roomFilter == "All" { return due }
        return due.filter { $0.roomZone == roomFilter }
    }

    private var upcoming: [Plant] {
        let soon = plants.filter { !$0.isDueToday }
        if roomFilter == "All" { return Array(soon.prefix(10)) }
        return Array(soon.filter { $0.roomZone == roomFilter }.prefix(10))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TrustBanner()
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section {
                    Picker("Room", selection: $roomFilter) {
                        ForEach(rooms, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Filter by room or zone")
                }

                if filteredDue.isEmpty && fertilizeDue.isEmpty && upcoming.isEmpty {
                    Section {
                        emptyState
                    }
                }

                if !filteredDue.isEmpty {
                    Section("Needs a soil check") {
                        ForEach(filteredDue) { plant in
                            DuePlantRow(plant: plant) {
                                soilCheckPlant = plant
                            } onSnooze: {
                                snooze(plant)
                            }
                        }
                    }
                }

                if !fertilizeDue.isEmpty {
                    Section("Feeding due") {
                        ForEach(fertilizeDue) { plant in
                            FertilizeDueRow(plant: plant) {
                                logFertilized(plant)
                            }
                        }
                    }
                }

                if !upcoming.isEmpty {
                    Section("Upcoming") {
                        ForEach(upcoming) { plant in
                            NavigationLink(value: plant.id) {
                                UpcomingRow(plant: plant)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Due Today")
            .navigationDestination(for: UUID.self) { id in
                if let plant = plants.first(where: { $0.id == id }) {
                    PlantDetailView(plant: plant)
                }
            }
            .sheet(item: $soilCheckPlant) { plant in
                SoilCheckFlowView(plant: plant)
            }
            .onAppear {
                WidgetDataWriter.write(plants: Array(plants))
                shareService.refresh(from: modelContext)
            }
            .onChange(of: plants.count) { _, _ in
                WidgetDataWriter.write(plants: Array(plants))
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing thirsty right now")
                .font(.headline)
            Text("When a check is due, we’ll ask you to feel the soil — not blindly water. \(AppConstants.trustTagline)")
                .font(.subheadline)
                .foregroundStyle(WatertruthTheme.muted)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func snooze(_ plant: Plant) {
        let outcome = engine.applySnooze(intervalDays: plant.intervalDays, days: 1)
        plant.nextDueAt = outcome.nextDueAt
        plant.updatedAt = Date()
        let by = shareService.currentCaretakerName()
        let event = CareEvent(kind: .snoozed, performedBy: by, note: "Quick snooze 1 day", plant: plant)
        plant.careEvents.append(event)
        Task { await NotificationService.shared.scheduleSoilCheck(for: plant.id, plantName: plant.nickname, at: plant.nextDueAt) }
        WidgetDataWriter.write(plants: Array(plants))
    }

    private func logFertilized(_ plant: Plant) {
        let by = shareService.currentCaretakerName()
        plant.logFertilized(performedBy: by)
        try? modelContext.save()
        if let at = plant.nextFertilizeAt {
            Task {
                await NotificationService.shared.scheduleFertilize(
                    for: plant.id,
                    plantName: plant.nickname,
                    at: at
                )
            }
        }
        WidgetDataWriter.write(plants: Array(plants))
    }
}

struct DuePlantRow: View {
    let plant: Plant
    var onCheck: () -> Void
    var onSnooze: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.nickname)
                        .font(.headline)
                    Text(plant.roomZone)
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)
                    if let who = plant.whoWateredLabel {
                        Text("Last: \(who)")
                            .font(.caption2)
                            .foregroundStyle(WatertruthTheme.earth)
                            .accessibilityLabel("Last watered by \(who)")
                    }
                }
                Spacer()
                Text(plant.learnedNextLabel)
                    .font(.caption2)
                    .foregroundStyle(WatertruthTheme.muted)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }
            HStack {
                Button(action: onCheck) {
                    Label("Check soil", systemImage: "hand.point.up.left.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(WatertruthTheme.leaf)
                .accessibilityLabel("Check soil for \(plant.nickname)")

                Button(action: onSnooze) {
                    Label("Snooze", systemImage: "moon.zzz")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Snooze reminder for \(plant.nickname)")
            }
        }
        .padding(.vertical, 4)
    }
}

struct FertilizeDueRow: View {
    let plant: Plant
    var onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.nickname)
                        .font(.headline)
                    Text(plant.roomZone)
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)
                    if let relative = plant.lastFertilizedRelativeLabel {
                        Text("Last fertilized \(relative)")
                            .font(.caption2)
                            .foregroundStyle(WatertruthTheme.earth)
                    } else {
                        Text("Fertilize due")
                            .font(.caption2)
                            .foregroundStyle(WatertruthTheme.moss)
                    }
                }
                Spacer()
                if let next = plant.nextFertilizeAt {
                    Text(next, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button(action: onLog) {
                Label("Log feeding", systemImage: "leaf.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(WatertruthTheme.moss)
            .accessibilityLabel("Log feeding for \(plant.nickname)")
        }
        .padding(.vertical, 4)
    }
}

struct UpcomingRow: View {
    let plant: Plant

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(plant.nickname)
                Text(plant.roomZone)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(plant.nextDueAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
