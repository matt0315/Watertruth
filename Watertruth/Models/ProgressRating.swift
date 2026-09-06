import Foundation

/// User-judged progress between photos — never AI/ML health scoring.
enum ProgressRating: String, Codable, CaseIterable, Identifiable {
    case better
    case same
    case worse

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .better: return "Better"
        case .same: return "Same"
        case .worse: return "Worse"
        }
    }

    var systemImage: String {
        switch self {
        case .better: return "arrow.up.right"
        case .same: return "equal"
        case .worse: return "arrow.down.right"
        }
    }
}
