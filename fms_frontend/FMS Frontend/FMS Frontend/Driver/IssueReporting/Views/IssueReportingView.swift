import SwiftUI
import PhotosUI

// MARK: - ReportIssueView

struct ReportIssueView: View {

    // Passed in from TripDetailView
    let trip: LifecycleTrip

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager()

    // MARK: Image state
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var cameraImage: UIImage? = nil
    @State private var photoPickerItems: [PhotosPickerItem] = []

    // MARK: Sheet / alert state
    @State private var showPermissionAlert = false

    // MARK: Submission state
    @State private var showSuccessAlert = false
    @State private var showImageSourcePopup = false

    // MARK: - Derived

    private var isNextEnabled: Bool {
        !speechManager.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !selectedImages.isEmpty
    }

    // Incident info derived from trip
    private var incidentLocation: String {
        "En route – \(trip.source) → \(trip.destination)"
    }
    private var vehicleUnit: String {
        trip.vehicleNumber ?? "Unassigned"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Background ─────────────────────────────────────────────
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    voiceInputCard
                    imageUploadSection
                    incidentInfoCard
                    
                    // The Next button now scrolls with the content
                    nextButton
                        .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .onTapGesture {
                // Dismiss keyboard when tapping background
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                // Also dismiss popup if it's showing
                if showImageSourcePopup {
                    withAnimation { showImageSourcePopup = false }
                }
            }

            // ── Custom Image Source Popup ────────────────────────────────
            if showImageSourcePopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showImageSourcePopup = false }
                    }

                imageSourcePopup
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .navigationTitle("Report Issue")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            speechManager.stopRecording()
        }
        // ── Camera sheet ───────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showCamera) {
            IssueReportingCameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: cameraImage) { img in
            if let img = img { selectedImages.append(img) }
        }
        // ── PhotosPicker result ────────────────────────────────────────────
        .onChange(of: photoPickerItems) { items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        await MainActor.run { selectedImages.append(img) }
                    }
                }
                await MainActor.run { photoPickerItems = [] }
            }
        }
        // ── Permission denied alert ────────────────────────────────────────
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow microphone and speech recognition access in Settings to use voice input.")
        }
        // ── Submission success alert ──────────────────────────────────────
        .alert("Issue Submitted Successfully", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your report has been recorded and the maintenance team has been notified.")
        }
    }

    // MARK: - Voice Input Card

    private var voiceInputCard: some View {
        VStack(spacing: 40) {

            // Mic button
            MicButton(state: speechManager.recordingState) {
                handleMicTap()
            }
            .padding(.top, 20)

            // Prominent Real-time transcription header
            Text("REAL-TIME TRANSCRIPTION")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .center)

            // ── Live transcription area ────────────────────────────────
            VStack(spacing: 8) {

                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if speechManager.transcript.isEmpty {
                        Text("Speak to describe the issue…")
                            .font(.body)
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $speechManager.transcript)
                        .font(.body)
                        .foregroundColor(Color(UIColor.label))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: 160) // Increased height for a more substantial card
                }
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // Audio waveform indicator (decorative)
                if speechManager.recordingState == .recording {
                    WaveformIndicator()
                        .frame(height: 28)
                        .padding(.top, 4)
                }
            }
        }
        .modifier(IssueCardModifier())
    }

    // MARK: - Image Upload Section

    private var imageUploadSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            imageUploadHeader
            imageUploadScrollRow
        }
        .modifier(IssueCardModifier())
    }

    private var imageUploadHeader: some View {
        HStack {
            Text("ADD IMAGES")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .tracking(1.2)

            Spacer()
        }
    }

    private var imageUploadScrollRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Selected images
                ForEach(0..<selectedImages.count, id: \.self) { i in
                    if i < selectedImages.count {
                        ImageThumbnail(image: selectedImages[i], size: 80.0) {
                            withAnimation {
                                if i < selectedImages.count {
                                    selectedImages.remove(at: i)
                                }
                            }
                        }
                    }
                }

                // Image holder field with popup options
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showImageSourcePopup = true
                    }
                } label: {
                    addMoreTile
                }
            }
            .padding(.vertical, 4.0)
        }
    }

    private var addMoreTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12.0)
                .stroke(Color(UIColor.systemGray3), style: StrokeStyle(lineWidth: 1.5, dash: [5.0]))
                .frame(width: 80.0, height: 80.0)

            Image(systemName: "plus")
                .font(.system(size: 22.0, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }

    // MARK: - Popup Helper

    private var imageSourcePopup: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { showImageSourcePopup = false }
                handleCameraButton()
            } label: {
                Text("Camera")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.label))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(25) // Capsule style
            }
            .padding(.bottom, 8)

            PhotosPicker(selection: $photoPickerItems,
                         maxSelectionCount: 10,
                         matching: .images) {
                Text("Photo Library")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.label))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(25) // Capsule style
            }
            .onChange(of: photoPickerItems) { _ in
                // Dismiss popup when selection starts or finished
                withAnimation { showImageSourcePopup = false }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
        .frame(width: 260)
        // Position it roughly in the center or near the add image field
        .padding(.bottom, 300) 
    }

    // MARK: - Incident Info Card

    private var incidentInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoRow(label: "INCIDENT LOCATION", value: incidentLocation, icon: "mappin.and.ellipse")
            Divider()
            infoRow(label: "VEHICLE UNIT", value: vehicleUnit, icon: "box.truck.fill")
        }
        .modifier(IssueCardModifier())
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            showSuccessAlert = true
        } label: {
            Text("Submit Issue")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isNextEnabled ? Color(red: 10/255, green: 48/255, blue: 58/255) : Color(UIColor.systemGray3))
                .cornerRadius(16)
                .animation(.easeInOut(duration: 0.2), value: isNextEnabled)
        }
        .disabled(!isNextEnabled)
    }

    // MARK: - Helpers

    private var cardBackground: Color {
        Color(UIColor.systemBackground)
    }

    private var micStateLabel: String {
        switch speechManager.recordingState {
        case .idle:      return "TAP TO START RECORDING"
        case .recording: return "LISTENING…"
        case .stopped:   return "TAP TO RECORD AGAIN"
        }
    }

    private func handleMicTap() {
        speechManager.requestPermissions { granted in
            guard granted else {
                showPermissionAlert = true
                return
            }
            speechManager.toggleRecording()
        }
    }

    private func handleCameraButton() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        showCamera = true
    }

    @ViewBuilder
    private func imageTile(systemIcon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemIcon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(Color(UIColor.label))
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(width: 80, height: 80)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func infoRow(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .tracking(1.1)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(UIColor.label))
        }
    }
}

// MARK: - Card Modifier

struct IssueCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Decorative Waveform Indicator

struct WaveformIndicator: View {
    @State private var animate = false

    private let barCount = 7
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 24

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 3,
                           height: animate
                               ? CGFloat.random(in: minHeight...maxHeight)
                               : minHeight)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.07),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

// MARK: - Preview

#Preview {
    ReportIssueView(trip: LifecycleTrip(
        id: "TRP-10488",
        source: "Bengaluru, KA",
        destination: "Mysuru, KA",
        status: .scheduled,
        dateValue: "Oct 20",
        timeLabel: "Scheduled Start",
        timeValue: "14:30",
        loadInfo: "12 Pallets",
        distance: 143.2,
        vehicleNumber: "MH01BK9392"
    ))
}
