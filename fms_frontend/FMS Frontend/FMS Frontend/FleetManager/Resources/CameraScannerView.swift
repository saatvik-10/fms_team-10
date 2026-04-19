import SwiftUI
internal import UIKit

struct CameraScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var didFinishScanning: (String, String, String, String) -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraScannerView
        
        init(_ parent: CameraScannerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // In a real OCR app, we would process the image here.
            // Since we're simulating OCR, we'll return mock data after a delay.
            
            parent.isPresented = false
            
            // Simulating processing delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Return dummy data based on common patterns
                self.parent.didFinishScanning(
                    "Vikram Singh Rathore",
                    "DL-992834-TX",
                    "12 / 24 / 2028",
                    "CLASS A, HAZMAT"
                )
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        picker.sourceType = .camera
        #endif
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
