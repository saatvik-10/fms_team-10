//
//  DrowsinessDetector.swift
//  FMS Frontend
//
//  Created by Mrunal Aralkar on 22/04/26.
//

import AVFoundation
import Vision
//import UIKit
import AudioToolbox
import Combine

class DrowsinessDetector: NSObject, ObservableObject {
    
    // MARK: - Published State
    @Published var isDetecting = false
    @Published var isDrowsy = false
    
    // MARK: - Private
    private var captureSession: AVCaptureSession?
    private var drowsyFrameCount = 0
    private let drowsyFrameThreshold = 20
    private var frameSkipCounter = 0
    
    // MARK: - Start Detection
    func startDetection() {
        // Show camera-in-use alert first, then start
        requestCameraPermission { [weak self] granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self?.setupCaptureSession()
            }
        }
    }
    
    // MARK: - Stop Detection
    func stopDetection() {
        captureSession?.stopRunning()
        captureSession = nil
        isDetecting = false
        drowsyFrameCount = 0
    }
    
    // MARK: - Camera Permission
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        default:
            completion(false)
        }
    }
    
    // MARK: - Setup Camera
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ), let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        session.addInput(input)
        
        // Lower frame rate to save battery
        try? device.lockForConfiguration()
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 10) // 10fps
        device.unlockForConfiguration()
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "drowsinessQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        session.addOutput(output)
        
        captureSession = session
        session.startRunning()
        
        DispatchQueue.main.async {
            self.isDetecting = true
        }
    }
    
    // MARK: - Eye Aspect Ratio
    private func eyeAspectRatio(points: [CGPoint]) -> CGFloat {
        guard points.count >= 6 else { return 1.0 }
        let v1 = hypot(points[1].x - points[5].x, points[1].y - points[5].y)
        let v2 = hypot(points[2].x - points[4].x, points[2].y - points[4].y)
        let h  = hypot(points[0].x - points[3].x, points[0].y - points[3].y)
        guard h > 0 else { return 1.0 }
        return (v1 + v2) / (2.0 * h)
    }
    
    // MARK: - Analyze Face
    private func analyzeFace(_ face: VNFaceObservation) {
        guard let landmarks = face.landmarks,
              let leftEye  = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            print("[Drowsy] Face found but NO eye landmarks detected")
            return
        }

        let leftEAR  = eyeAspectRatio(points: leftEye.normalizedPoints)
        let rightEAR = eyeAspectRatio(points: rightEye.normalizedPoints)
        let avgEAR   = (leftEAR + rightEAR) / 2.0

        print("[Drowsy] EAR: left=\(String(format: "%.3f", leftEAR)) right=\(String(format: "%.3f", rightEAR)) avg=\(String(format: "%.3f", avgEAR)) frames=\(drowsyFrameCount)")

        DispatchQueue.main.async {
            if avgEAR < 0.22 {
                self.drowsyFrameCount += 1
                if self.drowsyFrameCount >= self.drowsyFrameThreshold && !self.isDrowsy {
                    self.isDrowsy = true
                    self.triggerAlert()
                }
            } else if avgEAR > 0.25 {
                // Only reset when eyes are clearly open, not on borderline frames
                self.drowsyFrameCount = 0
                self.isDrowsy = false
            }
            // avgEAR between 0.22–0.25: do nothing, hold current count
        }
    }
    
    // MARK: - Trigger Alert
    private func triggerAlert() {
        // Vibration
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        }
        
        // Loud alert sound as backup
        AudioServicesPlayAlertSound(1005) // Standard iOS alert sound
    }
}

// MARK: - AVCapture Delegate
extension DrowsinessDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Process every 3rd frame to save CPU
        frameSkipCounter += 1
        guard frameSkipCounter % 3 == 0 else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let face = (req.results as? [VNFaceObservation])?.first else {
                print("[Drowsy] No face detected in frame")
                return
            }
            self?.analyzeFace(face)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored)
        try? handler.perform([request])
    }
}
