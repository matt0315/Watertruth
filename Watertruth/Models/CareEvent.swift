import Foundation
import SwiftData

@Model
final class CareEvent {
    var id: UUID
    var kindRaw: String
    var timestamp: Date
    var performedBy: String
    var soilMoistureRaw: String?
    var note: String?
    var intervalBefore: Double?
    var intervalAfter: Double?
    var plant: Plant?

    var kind: CareEventKind {
        get { CareEventKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    var soilMoisture: SoilMoisture? {
        get {
            guard let raw = soilMoistureRaw else { return nil }
            return SoilMoisture(rawValue: raw)
        }
        set { soilMoistureRaw = newValue?.rawValue }
    }

    init(
        kind: CareEventKind,
        performedBy: String,
        soilMoisture: SoilMoisture? = nil,
        note: String? = nil,
        intervalBefore: Double? = nil,
        intervalAfter: Double? = nil,
        plant: Plant? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.timestamp = Date()
        self.performedBy = performedBy
        self.soilMoistureRaw = soilMoisture?.rawValue
        self.note = note
        self.intervalBefore = intervalBefore
        self.intervalAfter = intervalAfter
        self.plant = plant
    }
}
