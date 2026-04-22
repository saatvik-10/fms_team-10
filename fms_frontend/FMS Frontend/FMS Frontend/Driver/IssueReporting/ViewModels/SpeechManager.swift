import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Recording State

enum RecordingState {
    case idle
    case recording
    case stopped
}

// MARK: - SpeechManager

final class SpeechManager: NSObject, ObservableObject {

    // MARK: Published
    @Published var transcript: String = ""
    @Published var recordingState: RecordingState = .idle
    @Published var permissionDenied: Bool = false

    // MARK: Private
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Holds the last stable transcript so edits are preserved
    private var committedText: String = ""

    // MARK: - Public API

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    self?.permissionDenied = true
                    completion(false)
                    return
                }
                if #available(iOS 17.0, *) {
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if !granted { self?.permissionDenied = true }
                            completion(granted)
                        }
                    }
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if !granted { self?.permissionDenied = true }
                            completion(granted)
                        }
                    }
                }
            }
        }
    }

    func startRecording() {
        // 1. Reset any existing state safely
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
        recognitionTask = nil

        // Commit current transcript to base text
        committedText = transcript.isEmpty ? "" : transcript + " "

        // 2. Setup Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("SpeechManager: AudioSession setup failed: \(error)")
            return
        }

        // 3. Create Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("SpeechManager: Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        // 4. Configure Audio Engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Safety: Ensure we have a valid format (Simulator can return 0 channels/sampleRate)
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("SpeechManager: Invalid audio format. Check simulator microphone settings.")
            return
        }

        // 5. Start Recognition Task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = self.committedText + result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
                self.recognitionTask = nil
            }
        }

        // 6. Install Tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        // 7. Start Engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.recordingState = .recording }
        } catch {
            print("SpeechManager: AudioEngine start failed: \(error)")
            self.stopRecording()
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // We DO NOT call recognitionTask?.cancel() here because we want 
        // the final results to be processed and returned in the callback.
        
        DispatchQueue.main.async {
            self.recordingState = .stopped
        }
        
        // Reset audio session category
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func toggleRecording() {
        switch recordingState {
        case .idle, .stopped:
            startRecording()
        case .recording:
            stopRecording()
        }
    }
}
