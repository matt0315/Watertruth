import WidgetKit
import SwiftUI

// MARK: - Shared snapshot types (duplicated lightly so the extension compiles standalone)

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

enum WidgetShared {
    static let appGroupID = "group.studio.botland.watertruth"
    static let snapshotKey = "widget.snapshot"

    static func read() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

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

struct ThirstyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ThirstyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThirstyEntry {
        ThirstyEntry(date: Date(), snapshot: WidgetShared.sample())
    }

    func getSnapshot(in context: Context, completion: @escaping (ThirstyEntry) -> Void) {
        let snap = WidgetShared.read() ?? WidgetShared.sample()
        completion(ThirstyEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThirstyEntry>) -> Void) {
        let snap = WidgetShared.read() ?? WidgetShared.sample()
        let entry = ThirstyEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ThirstyTodayWidget: Widget {
    let kind = "ThirstyTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThirstyTimelineProvider()) { entry in
            ThirstyTodayView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Thirsty today")
        .description("Needs-check count and next plants due for a soil check.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ThirstyTodayView: View {
    var entry: ThirstyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "drop.fill")
                Text("Check soil")
                    .font(.headline)
                Spacer()
                Text("\(entry.snapshot.thirstyCount)")
                    .font(.title2.weight(.bold))
                    .accessibilityLabel("\(entry.snapshot.thirstyCount) plants need a soil check")
            }
            if family == .systemMedium {
                ForEach(entry.snapshot.nextPlants.prefix(3)) { plant in
                    HStack {
                        Text(plant.nickname)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(plant.roomZone)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let first = entry.snapshot.nextPlants.first {
                Text(first.nickname)
                    .font(.subheadline)
                Text(first.roomZone)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("All clear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(4)
    }
}
