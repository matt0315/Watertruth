import Foundation
import SwiftData

@Model
final class HouseholdMember {
    var id: UUID
    var displayName: String
    /// CloudKit participant record name when signed in — TODO: wire CKShare.
    var cloudKitParticipantID: String?
    var isOwner: Bool
    var invitedAt: Date
    var acceptedAt: Date?

    init(displayName: String, isOwner: Bool = false, cloudKitParticipantID: String? = nil) {
        self.id = UUID()
        self.displayName = displayName
        self.cloudKitParticipantID = cloudKitParticipantID
        self.isOwner = isOwner
        self.invitedAt = Date()
        self.acceptedAt = isOwner ? Date() : nil
    }
}
