import Foundation

enum CareEventKind: String, Codable, CaseIterable, Identifiable {
    case soilCheck
    case watered
    case snoozed
    case fertilized
    case repotted
    case note
    case photo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soilCheck: return "Soil check"
        case .watered: return "Watered"
        case .snoozed: return "Snoozed"
        case .fertilized: return "Fertilized"
        case .repotted: return "Repotted"
        case .note: return "Note"
        case .photo: return "Photo"
        }
    }
}
