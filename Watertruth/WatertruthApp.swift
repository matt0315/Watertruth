import SwiftUI
import SwiftData
import UserNotifications

@main
struct WatertruthApp: App {
    @StateObject private var entitlements = EntitlementService.shared
    @StateObject private var shareService = ShareService.shared
    @StateObject private var sharePrompt = SharePromptService.shared
    @State private var showSplash = true

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
            ZStack {
                RootTabView()
                    .environmentObject(entitlements)
                    .environmentObject(shareService)
                    .environmentObject(sharePrompt)
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    BotlandSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                sharePrompt.recordLaunch()
                NotificationService.shared.registerCategories()
                _ = await NotificationService.shared.requestAuthorization()
                await entitlements.loadProducts()
                await entitlements.refreshEntitlements()
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
            .sheet(isPresented: $sharePrompt.shouldShowSharePrompt) {
                ShareWatertruthView(prompt: sharePrompt)
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
