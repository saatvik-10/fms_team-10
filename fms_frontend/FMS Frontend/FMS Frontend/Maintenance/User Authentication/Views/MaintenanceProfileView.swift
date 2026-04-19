//
//  MaintenanceProfileView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceProfileView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        List {
            // Identity Header
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppColors.primary)
                        .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 10))
                    
                    VStack(spacing: 4) {
                        Text("Anshul Kumaria")
                            .font(.title2.bold())
                        Text("Senior Maintenance Technician")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("ID: MS-7729-2026")
                            .font(.caption.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            

            Section("App Preferences") {
                ProfileMenuRow(title: "Notifications", icon: "bell.badge", color: .red)
                ProfileMenuRow(title: "Dark Mode", icon: "moon.fill", color: .purple)
                ProfileMenuRow(title: "Units of Measure (mi/mpg)", icon: "speedometer", color: .blue)
            }
            

            Section {
                Button(action: {
                    withAnimation {
                        isLoggedIn = false
                    }
                }) {
                    Text("Logout Session")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            
            Section {
                VStack(alignment: .center, spacing: 4) {
                    Text("Fleet Management System - Maintenance")
                    Text("Version 1.2.0 (Stable)")
                    Text("© 2026 FleetCore Pro")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                Text(title)
                    .font(.caption2.bold())
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
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            
            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
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
