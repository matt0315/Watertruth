import Foundation
import StoreKit

/// StoreKit 2 entitlement gate. Free tier: reminders for N=7 plants. No weekly SKU.
@MainActor
final class EntitlementService: ObservableObject {
    static let shared = EntitlementService()

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var trialEndDate: Date?
    @Published private(set) var purchaseError: String?

    /// Force Pro in DEBUG previews / simulator without StoreKit config if desired.
    var debugForcePro: Bool = false

    var freePlantLimit: Int { AppConstants.freePlantLimit }

    var effectiveIsPro: Bool { isPro || debugForcePro }

    func canAddPlant(currentCount: Int) -> Bool {
        if effectiveIsPro { return true }
        return currentCount < freePlantLimit
    }

    func plantsOverFreeLimit(count: Int) -> Int {
        max(0, count - freePlantLimit)
    }

    /// Free plants keep full reminders; only excess plants need Pro.
    func remindersAllowed(forPlantIndex index: Int) -> Bool {
        effectiveIsPro || index < freePlantLimit
    }

    func loadProducts() async {
        do {
            let ids: Set<String> = [
                AppConstants.ProductID.annual,
                AppConstants.ProductID.monthly,
                AppConstants.ProductID.lifetime
                // Intentionally NO weekly product ID
            ]
            products = try await Product.products(for: ids)
                .sorted { lhs, rhs in
                    // Annual primary first
                    rank(lhs.id) < rank(rhs.id)
                }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func rank(_ id: String) -> Int {
        switch id {
        case AppConstants.ProductID.annual: return 0
        case AppConstants.ProductID.monthly: return 1
        case AppConstants.ProductID.lifetime: return 2
        default: return 99
        }
    }

    func refreshEntitlements() async {
        var pro = false
        var trialEnd: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            switch transaction.productID {
            case AppConstants.ProductID.annual,
                 AppConstants.ProductID.monthly,
                 AppConstants.ProductID.lifetime:
                pro = true
                if let exp = transaction.expirationDate {
                    trialEnd = exp
                }
            default:
                break
            }
        }
        isPro = pro
        trialEndDate = trialEnd
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    if product.id == AppConstants.ProductID.annual,
                       let end = trialEndDate ?? Calendar.current.date(byAdding: .day, value: AppConstants.PricingCopy.trialDays, to: Date()) {
                        await NotificationService.shared.scheduleTrialEndingReminder(trialEndDate: end)
                    }
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// Opens Apple's Manage Subscriptions (honest billing UX).
    func manageSubscriptionsURL() -> URL {
        URL(string: "https://apps.apple.com/account/subscriptions")!
    }

    var freeTierSummary: String {
        "Free includes soil-check reminders for up to \(freePlantLimit) plants. Pro unlocks unlimited plants, household share, widget packs, CSV export, and seasonal insights."
    }
}
