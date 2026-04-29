//
//  MaintenanceUserAuthenticationView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceUserAuthenticationView: View {
    @StateObject private var viewModel = MaintenanceUserAuthenticationViewModel()
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo/Branding
                VStack(spacing: 15) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primary)
                        .accessibilityHidden(true)
                    
                    Text("FMS Maintenance")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(AppColors.primary)
                        .accessibilityAddTraits(.header)
                }
                
                // Login Card
                CardView {
                    VStack(spacing: 20) {
                        Text("Staff Login")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            customTextField(placeholder: "Staff Email", text: $viewModel.email, icon: "envelope.fill")
                            customSecureField(placeholder: "Password", text: $viewModel.password, icon: "lock.fill")
                        }
                        
                        if let error = viewModel.loginError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(AppColors.error)
                        }
                        
                        PrimaryButton(title: viewModel.isLoggingIn ? "Authenticating..." : "Login") {
                            viewModel.login()
                        }
                        
                        Button(action: { viewModel.resetPassword() }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(AppColors.primary)
                        }
                        .accessibilityLabel("Forgot Password")
                        .accessibilityHint("Double tap to reset your staff account password")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Fleet Management System v1.0")
                    .font(.caption2)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .onChange(of: viewModel.isAuthenticated) { authenticated in
            if authenticated {
                withAnimation {
                    isLoggedIn = true
                }
            }
        }
    }
    
    func customTextField(placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary.opacity(0.6))
                .frame(width: 30)
                .accessibilityHidden(true)
            TextField(placeholder, text: text)
                .autocapitalization(.none)
                .accessibilityLabel(placeholder)
                .accessibilityHint("Enter your \(placeholder.lowercased())")
        }
        .padding()
        .background(AppColors.secondaryBackground.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.divider))
    }
    
    func customSecureField(placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary.opacity(0.6))
                .frame(width: 30)
                .accessibilityHidden(true)
            SecureField(placeholder, text: text)
                .accessibilityLabel(placeholder)
                .accessibilityHint("Enter your \(placeholder.lowercased())")
        }
        .padding()
        .background(AppColors.secondaryBackground.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.divider))
    }
}

struct MaintenanceUserAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceUserAuthenticationView(isLoggedIn: .constant(false))
    }
}
