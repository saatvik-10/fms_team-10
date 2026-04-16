//
//  MaintenanceProfileView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceProfileView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Identity Section
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(AppColors.primary)
                            .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5))
                        
                        VStack(spacing: 4) {
                            Text("Anshul Kumaria")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Senior Maintenance Technician")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("ID: MS-7729-2026")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    HStack(spacing: 20) {
                        ProfileStatItem(title: "Completed", value: "142", icon: "wrench.fill")
                        ProfileStatItem(title: "Verifications", value: "98%", icon: "checkmark.seal.fill")
                        ProfileStatItem(title: "Hrs Logged", value: "1.2k", icon: "clock.fill")
                    }
                    .padding(.horizontal)
                    
                    // Settings & Actions
                    VStack(spacing: 0) {
                        ProfileMenuRow(title: "Notification Settings", icon: "bell.fill", color: .red)
                        Divider().padding(.leading, 56)
                        ProfileMenuRow(title: "Security & Privacy", icon: "lock.shield.fill", color: .blue)
                        Divider().padding(.leading, 56)
                        ProfileMenuRow(title: "Language (English)", icon: "globe", color: .green)
                        Divider().padding(.leading, 56)
                        ProfileMenuRow(title: "Help & Documentation", icon: "questionmark.circle.fill", color: .orange)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Logout Action
                    Button(action: {
                        withAnimation {
                            isLoggedIn = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "power")
                            Text("Logout Session")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Text("App Version 1.0.4 (Enterprise Build)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct ProfileMenuRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.secondaryText.opacity(0.3))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

struct MaintenanceProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceProfileView(isLoggedIn: .constant(true))
        }
    }
}
