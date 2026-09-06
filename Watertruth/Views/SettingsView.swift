import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementService
    @Query private var plants: [Plant]
    @Query private var events: [CareEvent]

    @State private var showPaywall = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var exportError: String?

    private let season = SeasonAdjuster()

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Text("Plan")
                        Spacer()
                        Text(entitlements.effectiveIsPro ? "Pro" : "Free (\(AppConstants.freePlantLimit) plants)")
                            .foregroundStyle(.secondary)
                    }
                    Button("Watertruth Pro") { showPaywall = true }
                    Button {
                        UIApplication.shared.open(entitlements.manageSubscriptionsURL())
                    } label: {
                        Label("Manage Subscription", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    if let end = entitlements.trialEndDate {
                        Text("Access / trial through \(end.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Household") {
                    NavigationLink("Share garden") {
                        HouseholdShareView()
                    }
                }

                Section("Backup & export") {
                    Text("SwiftData stores locally; flip CloudKit in WatertruthApp when the iCloud container is ready.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Export care log (CSV)") {
                        exportCSV()
                    }
                    if let exportError {
                        Text(exportError).font(.caption).foregroundStyle(.red)
                    }
                }

                Section("Season / locale") {
                    Text(season.explanation())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Trust") {
                    TrustBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Share") {
                    ShareLink(
                        item: AppConstants.Botland.appStoreURL,
                        subject: Text("Watertruth"),
                        message: Text(SharePromptService.shared.shareMessage)
                    ) {
                        Label("Share Watertruth with friends", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Botland Studio") {
                    Link(destination: AppConstants.Botland.contact) {
                        Label("Contact / website", systemImage: "globe")
                    }
                    Link(destination: AppConstants.Botland.privacy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: AppConstants.Botland.terms) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0 MVP")
                    Text("Soil-check-first watering reminders. Not a plant-ID megastore.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(AppConstants.Botland.studioName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showExporter) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }

    private func exportCSV() {
        guard entitlements.effectiveIsPro else {
            showPaywall = true
            return
        }
        do {
            let url = try ExportService().writeTempCSV(from: Array(events))
            exportURL = url
            showExporter = true
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}
