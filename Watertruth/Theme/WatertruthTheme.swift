import SwiftUI

/// Calm Scandinavian / green-earth palette.
enum WatertruthTheme {
    static let leaf = Color(red: 0.35, green: 0.55, blue: 0.40)
    static let moss = Color(red: 0.45, green: 0.58, blue: 0.42)
    static let earth = Color(red: 0.55, green: 0.45, blue: 0.35)
    static let sand = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let clay = Color(red: 0.90, green: 0.88, blue: 0.84)
    static let ink = Color(red: 0.18, green: 0.20, blue: 0.18)
    static let muted = Color(red: 0.45, green: 0.48, blue: 0.45)

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
