import SwiftUI
import PhotosUI

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct IssueReportingCameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: IssueReportingCameraPicker
        init(_ parent: IssueReportingCameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// MARK: - Square Image Thumbnail with Remove Button

struct ImageThumbnail: View {
    let image: UIImage
    let size: CGFloat
    var onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, Color.black.opacity(0.6))
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Mic Button with Pulse

struct MicButton: View {
    let state: RecordingState
    let action: () -> Void



    private var bgColor: Color {
        switch state {
        case .idle:    return Color(red: 10/255, green: 48/255, blue: 58/255)
        case .recording: return .red
        case .stopped: return Color(UIColor.systemGray3)
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: 72, height: 72)
                    .shadow(color: bgColor.opacity(0.35), radius: 12, x: 0, y: 6)

                Image(systemName: "mic.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: state)
    }
}
