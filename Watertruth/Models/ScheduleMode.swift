import Foundation

/// Adaptive learns from early/late/snooze; manual locks to a fixed interval.
enum ScheduleMode: String, Codable, CaseIterable, Identifiable {
    case adaptive
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adaptive: return "Adaptive (learns from you)"
        case .manual: return "Manual (every N days)"
        }
    }
}
