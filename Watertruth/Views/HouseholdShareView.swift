import SwiftUI
import SwiftData

/// Invite 2–3 caretakers. CloudKit sharing stubs with clear TODOs for signing.
struct HouseholdShareView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementService
    @EnvironmentObject private var shareService: ShareService
    @State private var inviteName = ""
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                Text("Share your garden with \(AppConstants.householdShareMax) caretakers. Live completion + who-watered attribution prevents double-watering.")
                    .font(.subheadline)
                    .foregroundStyle(WatertruthTheme.muted)
            }

            if !entitlements.effectiveIsPro {
                Section {
                    Button("Unlock household share with Pro") {
                        showPaywall = true
                    }
                }
            }

            Section("Household") {
                ForEach(shareService.members, id: \.id) { member in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(member.displayName)
                            Text(member.isOwner ? "Owner" : (member.acceptedAt == nil ? "Invited" : "Caretaker"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !member.isOwner {
                            Button("Remove", role: .destructive) {
                                shareService.remove(member, in: modelContext)
                            }
                        }
                    }
                }
            }

            Section {
                TextField("Caretaker name", text: $inviteName)
                Button("Invite") {
                    guard entitlements.effectiveIsPro else {
                        showPaywall = true
                        return
                    }
                    let name = inviteName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    _ = shareService.invite(displayName: name, in: modelContext)
                    inviteName = ""
                }
                .disabled(inviteName.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("TODO(CloudKit): Present ShareLink / UICloudSharingController after enabling iCloud container iCloud.studio.botland.watertruth and signing with your team. Local invites persist for UI/dev; they do not sync until CKShare is wired.")
                    .font(.caption2)
            }

            if let err = shareService.lastError {
                Section {
                    Text(err).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Household")
        .onAppear {
            shareService.ensureOwner(named: "You", in: modelContext)
            shareService.refresh(from: modelContext)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
