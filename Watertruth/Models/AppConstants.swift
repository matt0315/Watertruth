import Foundation

enum AppConstants {
    /// Free tier keeps full reminders for this many plants.
    static let freePlantLimit = 7
    /// Household share soft cap (2–3 caretakers).
    static let householdShareMax = 3
    static let appGroupID = "group.studio.botland.watertruth"
    static let trustTagline = "Guide, not gospel — always feel the soil."
    static let notAdviceDisclaimer = "Not professional horticultural advice. When in doubt, check the soil with your finger or a moisture meter."

    /// Studio-wide web (all Botland apps).
    enum Botland {
        static let site = URL(string: "https://botland.studio")!
        static let contact = URL(string: "https://botland.studio")!
        static let privacy = URL(string: "https://botland.studio/privacy")!
        static let terms = URL(string: "https://botland.studio/terms")!
        static let studioName = "Botland Studio"
        static let shareDelayDays = 3
        static let appStoreURL = URL(string: "https://apps.apple.com/app/id6809161990")!
    }

    enum ProductID {
        static let annual = "studio.botland.watertruth.pro.annual"
        static let monthly = "studio.botland.watertruth.pro.monthly"
        static let lifetime = "studio.botland.watertruth.pro.lifetime"
        /// Intentionally no weekly SKU.
    }

    enum PricingCopy {
        static let annual = "$34.99/year"
        static let annualLaunch = "$29.99/year (launch)"
        static let monthly = "$5.99/month"
        static let lifetime = "$59.99 lifetime"
        static let trialDays = 7
        static let trialReminderDay = 5
    }
}
