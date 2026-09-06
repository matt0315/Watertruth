import SwiftUI

struct ShareWatertruthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var prompt: SharePromptService
    @State private var activityItems: [Any] = []

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Loving Watertruth?")
                    .font(.title2.weight(.semibold))
                Text("If it’s helping your plants (and skipping the blind “water now” trap), share it with a friend who keeps houseplants.")
                    .foregroundStyle(.secondary)
                ShareLink(
                    item: AppConstants.Botland.appStoreURL,
                    subject: Text("Watertruth"),
                    message: Text(prompt.shareMessage)
                ) {
                    Label("Share with friends", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatertruthTheme.leaf)
                .simultaneousGesture(TapGesture().onEnded {
                    prompt.markShared()
                })
                Button("Not now") {
                    prompt.markPromptShown()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding(24)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        prompt.markPromptShown()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
