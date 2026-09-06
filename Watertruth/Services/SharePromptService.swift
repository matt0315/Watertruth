import Foundation
import SwiftUI

/// After a few days of use, nudge the user to share Watertruth with friends.
@MainActor
final class SharePromptService: ObservableObject {
    static let shared = SharePromptService()

    @Published var shouldShowSharePrompt = false

    private let defaults = UserDefaults.standard
    private let firstOpenKey = "botland.firstOpenDate"
    private let sharePromptShownKey = "botland.sharePromptShown"
    private let shareCompletedKey = "botland.shareCompleted"

    private init() {}

    func recordLaunch() {
        if defaults.object(forKey: firstOpenKey) == nil {
            defaults.set(Date(), forKey: firstOpenKey)
        }
        evaluate()
    }

    func evaluate() {
        guard !defaults.bool(forKey: sharePromptShownKey),
              !defaults.bool(forKey: shareCompletedKey),
              let first = defaults.object(forKey: firstOpenKey) as? Date else {
            shouldShowSharePrompt = false
            return
        }
        let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
        shouldShowSharePrompt = days >= AppConstants.Botland.shareDelayDays
    }

    func markPromptShown() {
        defaults.set(true, forKey: sharePromptShownKey)
        shouldShowSharePrompt = false
    }

    func markShared() {
        defaults.set(true, forKey: shareCompletedKey)
        defaults.set(true, forKey: sharePromptShownKey)
        shouldShowSharePrompt = false
    }

    var shareMessage: String {
        "I’ve been using Watertruth — soil-check-first plant watering that actually adapts. Check it out: \(AppConstants.Botland.appStoreURL.absoluteString)"
    }
}
