import SwiftUI
import UIKit

// MARK: - Adaptive color helper

extension Color {
    /// Resolves to `light` or `dark` from the current trait collection (follows system appearance).
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Convenience for sRGB triplets in 0…1.
    static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat),
        alpha: CGFloat = 1
    ) -> Color {
        adaptive(
            light: UIColor(red: light.0, green: light.1, blue: light.2, alpha: alpha),
            dark: UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: alpha)
        )
    }
}

// MARK: - Theme

/// Calm Scandinavian / green-earth palette that follows Light / Dark (and related) system appearance.
/// Never force `preferredColorScheme` at the app or root level — these colors adapt via trait collection.
enum WatertruthTheme {
    // Brand accents — similar in both modes; slightly lifted in dark for contrast on dark surfaces.
    static let leaf = Color.adaptive(
        light: (0.35, 0.55, 0.40),
        dark: (0.48, 0.72, 0.52)
    )
    static let moss = Color.adaptive(
        light: (0.45, 0.58, 0.42),
        dark: (0.55, 0.70, 0.52)
    )
    static let earth = Color.adaptive(
        light: (0.55, 0.45, 0.35),
        dark: (0.72, 0.62, 0.48)
    )

    // Surfaces — warm sand/clay in light; warm charcoal counterparts in dark.
    static let sand = Color.adaptive(
        light: (0.96, 0.95, 0.92),
        dark: (0.16, 0.17, 0.16)
    )
    static let clay = Color.adaptive(
        light: (0.90, 0.88, 0.84),
        dark: (0.24, 0.25, 0.24)
    )

    // Text — system semantic labels so Dynamic Type / accessibility contrast stay correct.
    static let ink = Color.primary
    static let muted = Color.secondary

    /// Full-bleed page chrome (lists, paywall shell). Prefer over sand for root backgrounds.
    static let pageBackground = Color(.systemBackground)
    /// Grouped / inset card chrome.
    static let groupedBackground = Color(.secondarySystemBackground)

    static let trustCaption = Font.subheadline.weight(.regular)
}

struct TrustBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppConstants.trustTagline)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WatertruthTheme.leaf)
            Text(AppConstants.notAdviceDisclaimer)
                .font(.caption)
                .foregroundStyle(WatertruthTheme.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatertruthTheme.sand)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
