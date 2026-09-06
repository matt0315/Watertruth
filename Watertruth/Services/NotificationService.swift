import Foundation
import UserNotifications

/// Builds soil-check and fertilize notifications.
/// Soil bodies MUST say "Check soil — {plant}", never bare "Water now".
/// Fertilize bodies use feed wording, e.g. "Time to feed {plant}".
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

    /// Schedule a check reminder for a plant. Cancels prior pending soil-check for that plant first.
    func scheduleSoilCheck(for plantID: UUID, plantName: String, at date: Date) async {
        await cancelSoilCheck(for: plantID)
        let content = UNMutableNotificationContent()
        content.title = "Watertruth"
        content.body = Self.soilCheckBody(plantName: plantName)
        content.sound = .default
        content.categoryIdentifier = "SOIL_CHECK"
        content.userInfo = ["plantID": plantID.uuidString, "kind": "soilCheck"]
        content.threadIdentifier = plantID.uuidString

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.soilCheckIdentifier(for: plantID),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Schedule a fertilize/feed reminder. Cancels prior pending fertilize for that plant first.
    func scheduleFertilize(for plantID: UUID, plantName: String, at date: Date) async {
        await cancelFertilize(for: plantID)
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Watertruth"
        content.body = Self.fertilizeBody(plantName: plantName)
        content.sound = .default
        content.categoryIdentifier = "FERTILIZE"
        content.userInfo = ["plantID": plantID.uuidString, "kind": "fertilize"]
        content.threadIdentifier = plantID.uuidString

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.fertilizeIdentifier(for: plantID),
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

    /// Cancels soil-check reminders only (does not touch fertilize).
    func cancel(for plantID: UUID) async {
        await cancelSoilCheck(for: plantID)
    }

    func cancelSoilCheck(for plantID: UUID) async {
        let id = Self.soilCheckIdentifier(for: plantID)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func cancelFertilize(for plantID: UUID) async {
        let id = Self.fertilizeIdentifier(for: plantID)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func clearDelivered(for plantID: UUID) {
        center.removeDeliveredNotifications(withIdentifiers: [
            Self.soilCheckIdentifier(for: plantID),
            Self.fertilizeIdentifier(for: plantID)
        ])
    }

    static func soilCheckBody(plantName: String) -> String {
        "Check soil — \(plantName)"
    }

    static func fertilizeBody(plantName: String) -> String {
        "Time to feed \(plantName)"
    }

    static func identifier(for plantID: UUID) -> String {
        soilCheckIdentifier(for: plantID)
    }

    static func soilCheckIdentifier(for plantID: UUID) -> String {
        "soil-check-\(plantID.uuidString)"
    }

    static func fertilizeIdentifier(for plantID: UUID) -> String {
        "fertilize-\(plantID.uuidString)"
    }

    private static func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    func registerCategories() {
        let check = UNNotificationAction(identifier: "OPEN_SOIL_CHECK", title: "Check soil", options: [.foreground])
        let soilCategory = UNNotificationCategory(
            identifier: "SOIL_CHECK",
            actions: [check],
            intentIdentifiers: [],
            options: []
        )
        let feed = UNNotificationAction(identifier: "OPEN_FERTILIZE", title: "Log feeding", options: [.foreground])
        let fertilizeCategory = UNNotificationCategory(
            identifier: "FERTILIZE",
            actions: [feed],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([soilCategory, fertilizeCategory])
    }
}
