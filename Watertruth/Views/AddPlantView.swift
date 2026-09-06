import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementService
    @EnvironmentObject private var shareService: ShareService

    @State private var nickname = ""
    @State private var speciesTag = ""
    @State private var roomZone = "Living room"
    @State private var potSize = "Medium"
    @State private var medium = "Potting mix"
    @State private var lightNote = "Bright indirect"
    @State private var isOutdoor = false
    @State private var intervalDays = 7
    @State private var photoData: Data?
    @State private var commonPlants: [CommonHouseplant] = CommonHouseplant.load()

    private let rooms = ["Living room", "Bedroom", "Kitchen", "Bathroom", "Office", "Balcony", "Patio", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Cover photo") {
                    PlantPhotoPickerRow(photoData: $photoData, title: "Plant cover", allowRemove: true)
                    Text("Optional. Shown on your plant list and detail — not for plant ID.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Profile") {
                    TextField("Nickname", text: $nickname)
                    Picker("Species (curated list)", selection: $speciesTag) {
                        Text("Custom / unknown").tag("")
                        ForEach(commonPlants) { p in
                            Text(p.name).tag(p.name)
                        }
                    }
                    if speciesTag.isEmpty {
                        TextField("Species tag", text: $speciesTag)
                    }
                    Picker("Room / zone", selection: $roomZone) {
                        ForEach(rooms, id: \.self) { Text($0) }
                    }
                    Toggle("Outdoor", isOn: $isOutdoor)
                }
                Section("Pot & light") {
                    TextField("Pot size", text: $potSize)
                    TextField("Medium", text: $medium)
                    TextField("Light note", text: $lightNote)
                }
                Section {
                    Stepper("Starting interval: \(intervalDays) days", value: $intervalDays, in: 2...30)
                    Text("We’ll ask you to check soil — not water blindly. Interval adapts unless you set a manual override.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Schedule")
                } footer: {
                    Text(AppConstants.trustTagline)
                }
            }
            .navigationTitle("Add plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        var startInterval = Double(intervalDays)
        if isOutdoor {
            startInterval = SeasonAdjuster().applySoftAdjust(baselineDays: startInterval)
        }
        let plant = Plant(
            nickname: nickname.trimmingCharacters(in: .whitespaces),
            speciesTag: speciesTag,
            roomZone: roomZone,
            potSize: potSize,
            medium: medium,
            lightNote: lightNote,
            isOutdoor: isOutdoor,
            intervalDays: startInterval,
            scheduleMode: .adaptive
        )
        plant.photoData = photoData
        modelContext.insert(plant)
        try? modelContext.save()
        Task {
            await NotificationService.shared.scheduleSoilCheck(
                for: plant.id,
                plantName: plant.nickname,
                at: plant.nextDueAt
            )
        }
        dismiss()
    }
}

struct CommonHouseplant: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var defaultIntervalDays: Int

    static func load() -> [CommonHouseplant] {
        guard let url = Bundle.main.url(forResource: "CommonHouseplants", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([CommonHouseplant].self, from: data) else {
            return [
                CommonHouseplant(name: "Monstera deliciosa", defaultIntervalDays: 7),
                CommonHouseplant(name: "Snake plant", defaultIntervalDays: 14),
                CommonHouseplant(name: "Pothos", defaultIntervalDays: 7),
                CommonHouseplant(name: "Peace lily", defaultIntervalDays: 5),
                CommonHouseplant(name: "Fiddle-leaf fig", defaultIntervalDays: 7)
            ]
        }
        return list
    }
}
