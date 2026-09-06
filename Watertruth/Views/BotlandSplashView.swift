import SwiftUI

/// Shared Botland Studio load screen shown on every cold start.
struct BotlandSplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.12, blue: 0.10)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.75, green: 0.86, blue: 0.78),
                                    Color(red: 0.45, green: 0.62, blue: 0.52)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color(red: 0.08, green: 0.14, blue: 0.12))
                }
                VStack(spacing: 6) {
                    Text(AppConstants.Botland.studioName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("building smarter ways to work")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Botland Studio")
        }
    }
}
