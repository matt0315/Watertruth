import Foundation

/// Result of a soil-check before deciding to water.
enum SoilMoisture: String, Codable, CaseIterable, Identifiable {
    case dry
    case moist
    case wet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dry: return "Dry"
        case .moist: return "Moist"
        case .wet: return "Wet"
        }
    }

    var guidance: String {
        switch self {
        case .dry: return "Soil feels dry — water now if the plant needs it."
        case .moist: return "Still moist — snooze and check again later."
        case .wet: return "Still wet — wait; overwatering causes root rot."
        }
    }

    var systemImage: String {
        switch self {
        case .dry: return "drop"
        case .moist: return "drop.fill"
        case .wet: return "drop.circle.fill"
        }
    }
}
