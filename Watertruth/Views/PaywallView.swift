import UIKit
import SwiftUI
import StoreKit

/// Honest monetization: annual primary, monthly, optional lifetime. NO weekly SKU.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementService
    @State private var purchasingID: String?
    @State private var showManage = false

    private var trialEndText: String {
        let end = Calendar.current.date(byAdding: .day, value: AppConstants.PricingCopy.trialDays, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: end)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Watertruth Pro")
                        .font(.largeTitle.weight(.bold))
                    Text(entitlements.freeTierSummary)
                        .font(.subheadline)
                        .foregroundStyle(WatertruthTheme.muted)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Unlimited plants", systemImage: "leaf.fill")
                        Label("Household share (2–3 caretakers)", systemImage: "person.2.fill")
                        Label("Who-watered sync", systemImage: "checkmark.bubble")
                        Label("Widget packs", systemImage: "rectangle.on.rectangle")
                        Label("CSV care-log export", systemImage: "square.and.arrow.up")
                        Label("Seasonal soft insights", systemImage: "sun.and.horizon")
                    }
                    .font(.subheadline)

                    // Annual — primary
                    productCard(
                        title: "Pro Annual",
                        price: AppConstants.PricingCopy.annual,
                        subtitle: "Primary plan · 7-day free trial · Trial ends \(trialEndText)",
                        badge: "Best value",
                        productID: AppConstants.ProductID.annual
                    )

                    productCard(
                        title: "Pro Monthly",
                        price: AppConstants.PricingCopy.monthly,
                        subtitle: "Cancel anytime in Manage Subscription",
                        badge: nil,
                        productID: AppConstants.ProductID.monthly
                    )

                    productCard(
                        title: "Lifetime",
                        price: AppConstants.PricingCopy.lifetime,
                        subtitle: "Optional one-time unlock",
                        badge: nil,
                        productID: AppConstants.ProductID.lifetime
                    )

                    Text("No weekly subscription. We won’t surprise you with a tiny weekly price that balloons yearly.")
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)

                    Text("Free tier keeps full soil-check reminders for \(AppConstants.freePlantLimit) plants — reminders are not paywalled for those plants.")
                        .font(.caption)
                        .foregroundStyle(WatertruthTheme.muted)

                    Button {
                        UIApplication.shared.open(entitlements.manageSubscriptionsURL())
                    } label: {
                        Label("Manage Subscription", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button("Restore purchases") {
                        Task { await entitlements.restore() }
                    }
                    .frame(maxWidth: .infinity)

                    if let err = entitlements.purchaseError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TrustBanner()
                }
                .padding()
            }
            .background(WatertruthTheme.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await entitlements.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func productCard(title: String, price: String, subtitle: String, badge: String?, productID: String) -> some View {
        let product = entitlements.products.first { $0.id == productID }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WatertruthTheme.leaf.opacity(0.2))
                        .clipShape(Capsule())
                }
                Spacer()
                Text(product?.displayPrice ?? price)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(WatertruthTheme.muted)
            Button {
                Task {
                    purchasingID = productID
                    if let product {
                        _ = await entitlements.purchase(product)
                    } else {
                        // StoreKit config missing on device — still show honest UI.
                        entitlements.debugForcePro = true
                    }
                    purchasingID = nil
                    if entitlements.effectiveIsPro { dismiss() }
                }
            } label: {
                if purchasingID == productID {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(productID == AppConstants.ProductID.annual ? "Start \(AppConstants.PricingCopy.trialDays)-day trial" : "Subscribe")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(WatertruthTheme.leaf)
            .accessibilityLabel("\(title) \(price)")
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
