import UIKit
import SwiftUI
import SwiftData
import PhotosUI

/// Photo journal timeline — growth story, not diagnosis.
struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant

    @State private var caption = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingPhoto: Data?

    private var entries: [JournalEntry] {
        plant.journalEntries.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Progress photos only — Watertruth does not diagnose disease or pests.")
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)
                }

                Section("Add entry") {
                    TextField("Caption (optional)", text: $caption)
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(pendingPhoto == nil ? "Choose photo" : "Photo selected", systemImage: "photo")
                    }
                    Button("Save to journal") {
                        saveEntry()
                    }
                    .disabled(pendingPhoto == nil && caption.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section("Timeline") {
                    if entries.isEmpty {
                        Text("No photos yet. Capture growth over time.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(entries, id: \.id) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                if let data = entry.photoData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(WatertruthTheme.clay)
                                        .frame(width: 64, height: 64)
                                        .overlay(Image(systemName: "photo"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !entry.caption.isEmpty {
                                        Text(entry.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        pendingPhoto = data
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(caption: caption, photoData: pendingPhoto, plant: plant)
        plant.journalEntries.append(entry)
        modelContext.insert(entry)
        caption = ""
        pendingPhoto = nil
        pickerItem = nil
        try? modelContext.save()
    }
}
