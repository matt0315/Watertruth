import SwiftUI
import PhotosUI
import UIKit

/// Compact cover / progress thumbnail from stored JPEG Data.
struct PlantPhotoThumbnail: View {
    let data: Data?
    var size: CGFloat = 52
    var cornerRadius: CGFloat = 10

    var body: some View {
        Group {
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    WatertruthTheme.clay
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(WatertruthTheme.leaf.opacity(0.55))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(data == nil)
    }
}

/// Hero image for plant detail.
struct PlantPhotoHero: View {
    let data: Data?
    var height: CGFloat = 200

    var body: some View {
        Group {
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    WatertruthTheme.sand
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(WatertruthTheme.leaf.opacity(0.6))
                        Text("Add a cover photo")
                            .font(.caption)
                            .foregroundStyle(WatertruthTheme.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Camera + library picker that writes compressed JPEG into `photoData`.
struct PlantPhotoPickerRow: View {
    @Binding var photoData: Data?
    var title: String = "Photo"
    var allowRemove: Bool = true

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PlantPhotoThumbnail(data: photoData, size: 64, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 12) {
                        if cameraAvailable {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                            }
                            .buttonStyle(.bordered)
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Library", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                    }
                    if allowRemove, photoData != nil {
                        Button("Remove photo", role: .destructive) {
                            photoData = nil
                            pickerItem = nil
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let compressed = ShareCardService.compressedJPEG(from: data) else { return }
                await MainActor.run { photoData = compressed }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let compressed = ShareCardService.compressedJPEG(from: image) {
                    photoData = compressed
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// UIKit camera wrapper.
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }
    }
}

/// System share sheet for a watermarked UIImage (+ optional text).
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
