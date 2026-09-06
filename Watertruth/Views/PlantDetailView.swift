import SwiftUI
import SwiftData
import UIKit

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var shareService: ShareService
    @Bindable var plant: Plant
    @State private var showSoilCheck = false
    @State private var showJournal = false
    @State private var showCompare = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var fertilizeNote = ""
    @State private var didLogFertilize = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    PlantPhotoHero(data: plant.photoData, height: 200)
                    PlantPhotoPickerRow(
                        photoData: Binding(
                            get: { plant.photoData },
                            set: { newValue in
                                plant.photoData = newValue
                                plant.updatedAt = Date()
                                try? modelContext.save()
                            }
                        ),
                        title: "Cover photo",
                        allowRemove: true
                    )
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
                    if let relative = plant.lastFertilizedRelativeLabel {
                        Text("Last fertilized \(relative)")
                            .font(.caption)
                            .foregroundStyle(WatertruthTheme.earth)
                            .accessibilityLabel("Last fertilized \(relative)")
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

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Note (optional)", text: $fertilizeNote)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Optional feeding note")

                    Button {
                        logFertilized()
                    } label: {
                        Label("Log feeding", systemImage: "leaf.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatertruthTheme.moss)
                    .accessibilityLabel("Log feeding for \(plant.nickname)")

                    if didLogFertilize {
                        Text("Feeding logged — next reminder scheduled.")
                            .font(.caption)
                            .foregroundStyle(WatertruthTheme.leaf)
                    } else if plant.fertilizeEnabled, let next = plant.nextFertilizeAt {
                        HStack(spacing: 4) {
                            Text("Next feed ~")
                            Text(next, style: .date)
                        }
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)
                    } else {
                        Text("Simple feed tracker — not a nutrient calculator.")
                            .font(.caption)
                            .foregroundStyle(WatertruthTheme.muted)
                    }
                }
                .padding(.vertical, 4)

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

                Button {
                    showCompare = true
                } label: {
                    Label("Compare progress", systemImage: "rectangle.split.2x1")
                }

                Button {
                    shareLatestProgress()
                } label: {
                    Label("Share progress photo", systemImage: "square.and.arrow.up")
                }
                .disabled(!canShareProgress)
            }

            Section("Secondary reminders") {
                Toggle("Fertilize reminders", isOn: Binding(
                    get: { plant.fertilizeEnabled },
                    set: { newValue in
                        plant.fertilizeEnabled = newValue
                        plant.updatedAt = Date()
                        if newValue {
                            if plant.nextFertilizeAt == nil {
                                plant.nextFertilizeAt = Calendar.current.date(
                                    byAdding: .day,
                                    value: plant.fertilizeIntervalDays,
                                    to: Date()
                                )
                            }
                            if let at = plant.nextFertilizeAt {
                                Task {
                                    await NotificationService.shared.scheduleFertilize(
                                        for: plant.id,
                                        plantName: plant.nickname,
                                        at: at
                                    )
                                }
                            }
                        } else {
                            Task { await NotificationService.shared.cancelFertilize(for: plant.id) }
                        }
                        try? modelContext.save()
                    }
                ))
                if plant.fertilizeEnabled {
                    Stepper(
                        "Every \(plant.fertilizeIntervalDays) days",
                        value: Binding(
                            get: { plant.fertilizeIntervalDays },
                            set: { newValue in
                                plant.fertilizeIntervalDays = newValue
                                plant.updatedAt = Date()
                                try? modelContext.save()
                            }
                        ),
                        in: 14...90
                    )
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
                        HStack(alignment: .top, spacing: 10) {
                            if let data = event.photoData {
                                PlantPhotoThumbnail(data: data, size: 44, cornerRadius: 8)
                            }
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
                                if let rating = event.progressRating {
                                    Text("Progress: \(rating.displayName)")
                                        .font(.caption2)
                                        .foregroundStyle(WatertruthTheme.leaf)
                                }
                                if let note = event.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundStyle(WatertruthTheme.muted)
                                }
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
        .sheet(isPresented: $showCompare) {
            CompareProgressView(plant: plant)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ActivityShareSheet(items: [
                    shareImage,
                    "\(plant.nickname) — Check Soil. Water Smarter. via Watertruth"
                ])
            }
        }
    }

    private var canShareProgress: Bool {
        plant.photoData != nil || plant.careEvents.contains(where: { $0.photoData != nil })
    }

    private func logFertilized() {
        let by = shareService.currentCaretakerName()
        plant.logFertilized(performedBy: by, note: fertilizeNote)
        try? modelContext.save()
        fertilizeNote = ""
        didLogFertilize = true
        if let at = plant.nextFertilizeAt {
            Task {
                await NotificationService.shared.scheduleFertilize(
                    for: plant.id,
                    plantName: plant.nickname,
                    at: at
                )
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            didLogFertilize = false
        }
    }

    private func shareLatestProgress() {
        let comparison = ProgressComparison.resolve(for: plant)
        let before = comparison.beforeData.flatMap { UIImage(data: $0) }
        let after = comparison.afterData.flatMap { UIImage(data: $0) }
        guard let image = ShareCardService.makeShareImage(
            before: before,
            after: after,
            plantName: plant.nickname
        ) else { return }
        shareImage = image
        showShareSheet = true
    }
}
