import Foundation
import SwiftData
import CloudKit

/// Household share for 2–3 caretakers via CloudKit.
/// TODO: Complete CKShare flow once iCloud container + signing are configured on Mac.
@MainActor
final class ShareService: ObservableObject {
    static let shared = ShareService()

    @Published var members: [HouseholdMember] = []
    @Published var lastError: String?

    var maxMembers: Int { AppConstants.householdShareMax }

    var canInviteMore: Bool {
        // Owner + invitees, soft cap 2–3 total caretakers beyond self is OK — cap total at maxMembers + 1 owner.
        members.filter { !$0.isOwner }.count < maxMembers
    }

    func ensureOwner(named name: String, in context: ModelContext) {
        let descriptor = FetchDescriptor<HouseholdMember>(predicate: #Predicate { $0.isOwner == true })
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let owner = HouseholdMember(displayName: name, isOwner: true)
            context.insert(owner)
            members = [owner]
        } else {
            members = existing
        }
    }

    func refresh(from context: ModelContext) {
        let descriptor = FetchDescriptor<HouseholdMember>(sortBy: [SortDescriptor(\.invitedAt)])
        members = (try? context.fetch(descriptor)) ?? []
    }

    /// Local stub invite — persists a pending member. Wire CKShare on device.
    func invite(displayName: String, in context: ModelContext) -> Bool {
        guard canInviteMore else {
            lastError = "Household share supports up to \(maxMembers) caretakers."
            return false
        }
        let member = HouseholdMember(displayName: displayName, isOwner: false)
        context.insert(member)
        refresh(from: context)
        // TODO(CloudKit): Create CKShare on the garden zone record, add CKShare.Participant,
        // present UICloudSharingController / ShareLink, map participant recordName → cloudKitParticipantID.
        return true
    }

    func remove(_ member: HouseholdMember, in context: ModelContext) {
        guard !member.isOwner else { return }
        // TODO(CloudKit): Revoke CKShare participant.
        context.delete(member)
        refresh(from: context)
    }

    /// Current caretaker display name for who-watered attribution.
    func currentCaretakerName(fallback: String = "You") -> String {
        members.first(where: { $0.isOwner })?.displayName ?? fallback
    }
}
