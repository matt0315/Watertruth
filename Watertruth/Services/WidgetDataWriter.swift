import Foundation

/// Writes glanceable Due Today snapshot into the App Group for WidgetKit.
struct WidgetSnapshotPlant: Codable, Identifiable, Hashable {
    var id: UUID
    var nickname: String
    var roomZone: String
    var nextDueAt: Date
    var lastWateredBy: String?
}

struct WidgetSnapshot: Codable {
    var updatedAt: Date
    var thirstyCount: Int
    var nextPlants: [WidgetSnapshotPlant]
}

enum WidgetDataWriter {
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupID)
    }

    static let snapshotKey = "widget.snapshot"

    static func write(plants: [Plant]) {
        let due = plants
            .filter { !$0.isArchived && $0.isDueToday }
            .sorted { $0.nextDueAt < $1.nextDueAt }
        let next = Array(due.prefix(3)).map {
            WidgetSnapshotPlant(
                id: $0.id,
                nickname: $0.nickname,
                roomZone: $0.roomZone,
                nextDueAt: $0.nextDueAt,
                lastWateredBy: $0.lastWateredBy
            )
        }
        let snapshot = WidgetSnapshot(
            updatedAt: Date(),
            thirstyCount: due.count,
            nextPlants: next
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: snapshotKey)
        }
    }

    static func read() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Sample data when App Group is empty (widget gallery / first launch).
    static func sample() -> WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: Date(),
            thirstyCount: 2,
            nextPlants: [
                WidgetSnapshotPlant(id: UUID(), nickname: "Monstera", roomZone: "Living room", nextDueAt: Date(), lastWateredBy: "Alex"),
                WidgetSnapshotPlant(id: UUID(), nickname: "Snake plant", roomZone: "Bedroom", nextDueAt: Date(), lastWateredBy: nil),
                WidgetSnapshotPlant(id: UUID(), nickname: "Pothos", roomZone: "Kitchen", nextDueAt: Date().addingTimeInterval(86400), lastWateredBy: "You")
            ]
        )
    }
}
