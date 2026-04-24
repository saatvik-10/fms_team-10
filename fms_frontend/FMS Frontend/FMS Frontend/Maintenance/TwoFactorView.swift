//
//  TwoFactorView.swift
//  FMS Frontend
//

import SwiftUI
import Combine

struct TwoFactorView: View {
    @Binding var userRole: AppUserRole
    let otpEmail: String
    let roleToSet: AppUserRole
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var otpError: String?
    @State private var showSuccessPopup = false
    @State private var timeRemaining = 60
    @State private var canResend = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var isVerifyEnabled: Bool {
        otpDigits.allSatisfy { !$0.isEmpty }
    }
    
    var body: some View {
        ZStack {
            // Background Image - Full visibility (Matching LoginView)
            Image("login_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Very light overshadow
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            LoginGridView()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Content Card
                VStack(spacing: 45) {
                    VStack(spacing: 16) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        
                        Text("Verification")
                            .font(.system(size: 32, weight: .black))
                            .tracking(1)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        
                        Text("Enter the 6-digit code sent to your email")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.center)

                        Text(otpEmail)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // OTP Input Boxes
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            otpBox(index: index)
                        }
                    }

                    if let otpError {
                        Text(otpError)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Verify Button
                    Button(action: {
                        Task {
                            await verifyOTP()
                        }
                    }) {
                        ZStack {
                            if isVerifying {
                                ProgressView().tint(AppColors.primary)
                            } else {
                                Text("Verify Account")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isVerifyEnabled ? Color.white : Color.white.opacity(0.3))
                        .foregroundColor(isVerifyEnabled ? AppColors.primary : .gray)
                        .cornerRadius(12)
                        .shadow(color: isVerifyEnabled ? Color.white.opacity(0.2) : .clear, radius: 10, y: 5)
                    }
                    .disabled(!isVerifyEnabled || isVerifying || isResending)
                    
                    VStack(spacing: 12) {
                        if !canResend {
                            Text("Resend code in \(timeRemaining)s")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Button(action: {
                            Task {
                                await resendOTP()
                            }
                        }) {
                            Text(isResending ? "Sending..." : "Resend OTP")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(canResend ? .white : .white.opacity(0.3))
                                .underline(canResend)
                        }
                        .disabled(!canResend || isVerifying || isResending)
                    }
                    .onReceive(timer) { _ in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            canResend = true
                        }
                    }
                }
                .padding(35)
                .frame(maxWidth: 500) // Constraint for iPad
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white.opacity(0.2))
                )
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 30) // Screen padding
                
                Spacer()
            }
            .blur(radius: showSuccessPopup ? 10 : 0)
            .disabled(showSuccessPopup)
            
            // Success Popup
            if showSuccessPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.success)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Login Successful")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Text("Welcome back to Fleetro")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(40)
                .frame(width: 320)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.2))
                )
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(showSuccessPopup)
        .onAppear {
            focusedIndex = 0
        }
    }
    
    @ViewBuilder
    private func otpBox(index: Int) -> some View {
        let borderColor: Color = focusedIndex == index ? Color.white.opacity(0.6) : Color.white.opacity(0.2)
        
        TextField("", text: $otpDigits[index])
            .frame(width: 44, height: 55)
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .focused($focusedIndex, equals: index)
            .onChange(of: otpDigits[index]) { oldValue, newValue in
                // Filter to numbers only
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    otpDigits[index] = filtered
                    return
                }
                
                if filtered.count > 1 {
                    otpDigits[index] = String(filtered.last!)
                }
                
                if !filtered.isEmpty {
                    if index < 5 {
                        focusedIndex = index + 1
                    } else {
                        focusedIndex = nil
                    }
                }
            }
    }
    
    @MainActor
    private func verifyOTP() async {
        otpError = nil
        isVerifying = true

        defer {
            isVerifying = false
        }

        let otp = otpDigits.joined()

        do {
            let response = try await AuthAPI.shared.verifyOTP(email: otpEmail, otp: otp)
            guard response.value.lowercased() == "success" else {
                otpError = "Invalid OTP. Please try again."
                return
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccessPopup = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                userRole = roleToSet
            }
        } catch {
            otpError = error.localizedDescription
        }
    }

    @MainActor
    private func resendOTP() async {
        otpError = nil
        isResending = true

        defer {
            isResending = false
        }

        do {
            _ = try await AuthAPI.shared.sendOTP(email: otpEmail)
            timeRemaining = 60
            canResend = false
            otpDigits = Array(repeating: "", count: 6)
            focusedIndex = 0
        } catch {
            otpError = error.localizedDescription
        }
    }
}

#Preview {
    TwoFactorView(userRole: .constant(.manager), otpEmail: "demo@fms.com", roleToSet: .manager)
}
