import Foundation
import UserNotifications

/// Builds soil-check notifications. Bodies MUST say "Check soil — {plant}", never bare "Water now".
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule a check reminder for a plant. Cancels prior pending for that plant first.
    func scheduleSoilCheck(for plantID: UUID, plantName: String, at date: Date) async {
        await cancel(for: plantID)
        let content = UNMutableNotificationContent()
        content.title = "Watertruth"
        content.body = Self.soilCheckBody(plantName: plantName)
        content.sound = .default
        content.categoryIdentifier = "SOIL_CHECK"
        content.userInfo = ["plantID": plantID.uuidString]
        content.threadIdentifier = plantID.uuidString

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.identifier(for: plantID),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Day-5 trial reminder: honest billing nudge before annual charge.
    func scheduleTrialEndingReminder(trialEndDate: Date) async {
        let reminderDay = Calendar.current.date(
            byAdding: .day,
            value: -(AppConstants.PricingCopy.trialDays - AppConstants.PricingCopy.trialReminderDay),
            to: trialEndDate
        ) ?? trialEndDate
        guard reminderDay > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trial ending soon"
        content.body = "Your Watertruth Pro trial ends on \(Self.format(trialEndDate)). Manage Subscription anytime in Settings."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDay)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "trial-ending", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(for plantID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: plantID)])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier(for: plantID)])
    }

    func clearDelivered(for plantID: UUID) {
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier(for: plantID)])
    }

    static func soilCheckBody(plantName: String) -> String {
        "Check soil — \(plantName)"
    }

    static func identifier(for plantID: UUID) -> String {
        "soil-check-\(plantID.uuidString)"
    }

    private static func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    func registerCategories() {
        let check = UNNotificationAction(identifier: "OPEN_SOIL_CHECK", title: "Check soil", options: [.foreground])
        let category = UNNotificationCategory(
            identifier: "SOIL_CHECK",
            actions: [check],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }
}
