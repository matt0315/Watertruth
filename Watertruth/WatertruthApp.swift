import SwiftUI
import SwiftData
import UserNotifications

@main
struct WatertruthApp: App {
    @StateObject private var entitlements = EntitlementService.shared
    @StateObject private var shareService = ShareService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Plant.self,
            CareEvent.self,
            JournalEntry.self,
            HouseholdMember.self
        ])
        // CloudKit-ready: flip cloudKitDatabase to .automatic once container is provisioned.
        let config = ModelConfiguration(
            "Watertruth",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // TODO: .automatic when iCloud.com.botlandstudio.watertruth is live
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(entitlements)
                .environmentObject(shareService)
                .task {
                    NotificationService.shared.registerCategories()
                    _ = await NotificationService.shared.requestAuthorization()
                    await entitlements.loadProducts()
                    await entitlements.refreshEntitlements()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            DueTodayView()
                .tabItem { Label("Due Today", systemImage: "drop.fill") }
            PlantListView()
                .tabItem { Label("Plants", systemImage: "leaf.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(WatertruthTheme.leaf)
    }
}
