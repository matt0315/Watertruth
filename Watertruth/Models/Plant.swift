import Foundation
import SwiftData

@Model
final class Plant {
    var id: UUID
    var nickname: String
    /// Manual species tag or curated picker — NOT cloud mega-ID.
    var speciesTag: String
    var roomZone: String
    var potSize: String
    var medium: String
    var lightNote: String
    var isOutdoor: Bool
    var photoData: Data?

    // Scheduling
    var scheduleModeRaw: String
    var intervalDays: Double
    /// Baseline before learning drift (adaptive mode).
    var baselineIntervalDays: Double
    var nextDueAt: Date
    var lastWateredAt: Date?
    var lastWateredBy: String?
    var lastSoilMoistureRaw: String?

    // Secondary care (optional toggles)
    var fertilizeEnabled: Bool
    var fertilizeIntervalDays: Int
    var nextFertilizeAt: Date?
    var repotEnabled: Bool
    var repotIntervalDays: Int
    var nextRepotAt: Date?

    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant)
    var careEvents: [CareEvent]

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.plant)
    var journalEntries: [JournalEntry]

    var scheduleMode: ScheduleMode {
        get { ScheduleMode(rawValue: scheduleModeRaw) ?? .adaptive }
        set { scheduleModeRaw = newValue.rawValue }
    }

    var lastSoilMoisture: SoilMoisture? {
        get {
            guard let raw = lastSoilMoistureRaw else { return nil }
            return SoilMoisture(rawValue: raw)
        }
        set { lastSoilMoistureRaw = newValue?.rawValue }
    }

    init(
        nickname: String,
        speciesTag: String = "",
        roomZone: String = "Living room",
        potSize: String = "Medium",
        medium: String = "Potting mix",
        lightNote: String = "Bright indirect",
        isOutdoor: Bool = false,
        intervalDays: Double = 7,
        scheduleMode: ScheduleMode = .adaptive
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.speciesTag = speciesTag
        self.roomZone = roomZone
        self.potSize = potSize
        self.medium = medium
        self.lightNote = lightNote
        self.isOutdoor = isOutdoor
        self.photoData = nil
        self.scheduleModeRaw = scheduleMode.rawValue
        self.intervalDays = intervalDays
        self.baselineIntervalDays = intervalDays
        self.nextDueAt = Calendar.current.date(byAdding: .day, value: Int(intervalDays.rounded()), to: Date()) ?? Date()
        self.lastWateredAt = nil
        self.lastWateredBy = nil
        self.lastSoilMoistureRaw = nil
        self.fertilizeEnabled = false
        self.fertilizeIntervalDays = 30
        self.nextFertilizeAt = nil
        self.repotEnabled = false
        self.repotIntervalDays = 365
        self.nextRepotAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
        self.careEvents = []
        self.journalEntries = []
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(nextDueAt) || nextDueAt < Date()
    }

    var learnedNextLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateStr = formatter.string(from: nextDueAt)
        if scheduleMode == .manual {
            return "Next check ~\(dateStr) (every \(Int(intervalDays.rounded())) days)"
        }
        return "Next water ~\(dateStr) (learned from you)"
    }

    var whoWateredLabel: String? {
        guard let by = lastWateredBy, let at = lastWateredAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "\(by) · \(formatter.localizedString(for: at, relativeTo: Date()))"
    }
}
