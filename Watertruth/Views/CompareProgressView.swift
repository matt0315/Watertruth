import SwiftUI
import SwiftData
import UIKit

/// Side-by-side last two progress photos (or cover + latest). User taps Better / Same / Worse.
struct CompareProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var savedRating: ProgressRating?

    private var comparison: ProgressComparison {
        ProgressComparison.resolve(for: plant)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("You decide how it’s going — Watertruth never scores plant health.")
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)

                    if comparison.hasAnyPhoto {
                        HStack(alignment: .top, spacing: 12) {
                            comparePanel(
                                title: comparison.beforeLabel,
                                date: comparison.beforeDate,
                                data: comparison.beforeData
                            )
                            comparePanel(
                                title: comparison.afterLabel,
                                date: comparison.afterDate,
                                data: comparison.afterData
                            )
                        }

                        if comparison.newerEvent != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How does the newer photo look?")
                                    .font(.subheadline.weight(.semibold))
                                HStack(spacing: 10) {
                                    ForEach(ProgressRating.allCases) { rating in
                                        Button {
                                            saveRating(rating)
                                        } label: {
                                            Label(rating.displayName, systemImage: rating.systemImage)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(tint(for: rating))
                                        .opacity(savedRating == nil || savedRating == rating ? 1 : 0.45)
                                    }
                                }
                                if let savedRating {
                                    Text("Saved: \(savedRating.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(WatertruthTheme.leaf)
                                }
                            }
                        }

                        Button {
                            exportShare()
                        } label: {
                            Label("Share before & after", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WatertruthTheme.leaf)
                        .disabled(!comparison.hasAnyPhoto)
                    } else {
                        ContentUnavailableView {
                            Label("No photos yet", systemImage: "photo.on.rectangle.angled")
                        } description: {
                            Text("Add a cover photo or attach a progress photo when you check soil.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Compare progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage {
                    ActivityShareSheet(items: [
                        shareImage,
                        "\(plant.nickname) — Check Soil. Water Smarter. via Watertruth"
                    ])
                }
            }
            .onAppear {
                savedRating = comparison.newerEvent?.progressRating
            }
        }
    }

    @ViewBuilder
    private func comparePanel(title: String, date: Date?, data: Data?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WatertruthTheme.muted)
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WatertruthTheme.clay)
                    .frame(height: 220)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(WatertruthTheme.muted)
                    }
            }
            if let date {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tint(for rating: ProgressRating) -> Color {
        switch rating {
        case .better: return WatertruthTheme.leaf
        case .same: return WatertruthTheme.earth
        case .worse: return Color.orange.opacity(0.85)
        }
    }

    private func saveRating(_ rating: ProgressRating) {
        guard let event = comparison.newerEvent else { return }
        event.progressRating = rating
        plant.updatedAt = Date()
        try? modelContext.save()
        savedRating = rating
    }

    private func exportShare() {
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

/// Picks the two photos to compare: last two CareEvents with photos, else cover + latest care photo.
struct ProgressComparison {
    var beforeData: Data?
    var afterData: Data?
    var beforeDate: Date?
    var afterDate: Date?
    var beforeLabel: String
    var afterLabel: String
    /// The newer CareEvent that receives Better/Same/Worse (nil when after is only cover).
    var newerEvent: CareEvent?

    var hasAnyPhoto: Bool { beforeData != nil || afterData != nil }

    static func resolve(for plant: Plant) -> ProgressComparison {
        let withPhotos = plant.careEvents
            .filter { $0.photoData != nil }
            .sorted { $0.timestamp > $1.timestamp }

        if withPhotos.count >= 2 {
            let newer = withPhotos[0]
            let older = withPhotos[1]
            return ProgressComparison(
                beforeData: older.photoData,
                afterData: newer.photoData,
                beforeDate: older.timestamp,
                afterDate: newer.timestamp,
                beforeLabel: "Before",
                afterLabel: "After",
                newerEvent: newer
            )
        }

        if let latest = withPhotos.first {
            if let cover = plant.photoData {
                return ProgressComparison(
                    beforeData: cover,
                    afterData: latest.photoData,
                    beforeDate: plant.createdAt,
                    afterDate: latest.timestamp,
                    beforeLabel: "Cover",
                    afterLabel: "Latest",
                    newerEvent: latest
                )
            }
            return ProgressComparison(
                beforeData: nil,
                afterData: latest.photoData,
                beforeDate: nil,
                afterDate: latest.timestamp,
                beforeLabel: "Before",
                afterLabel: "Latest",
                newerEvent: latest
            )
        }

        if let cover = plant.photoData {
            return ProgressComparison(
                beforeData: cover,
                afterData: nil,
                beforeDate: plant.createdAt,
                afterDate: nil,
                beforeLabel: "Cover",
                afterLabel: "After",
                newerEvent: nil
            )
        }

        return ProgressComparison(
            beforeData: nil,
            afterData: nil,
            beforeDate: nil,
            afterDate: nil,
            beforeLabel: "Before",
            afterLabel: "After",
            newerEvent: nil
        )
    }
}
