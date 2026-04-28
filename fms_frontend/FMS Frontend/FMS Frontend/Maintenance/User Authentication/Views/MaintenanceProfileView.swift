//
//  MaintenanceProfileView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var store = MaintenanceStore()
    
    private var profile: UserProfile? {
        store.currentProfile
    }
    
    private var joinedDate: String {
        profile?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }
    
    var body: some View {
        Group {
            if store.isLoadingProfile {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                mainContent
            }
        }
        .task {
            await store.loadProfile()
        }
    }
    
    private var mainContent: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppColors.primary)
                    
                    VStack(spacing: 4) {
                        Text(profile?.name ?? "Maintenance")
                            .font(.title2.bold())
                        Text("Senior Maintenance Technician")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                    }
                    

                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            
            Section("Account Details") {
                AppProfileInfoRow(label: "USERNAME", value: profile?.username ?? "-")
                AppProfileInfoRow(label: "PHONE", value: profile?.phone ?? "-")
                AppProfileInfoRow(label: "EMAIL", value: profile?.email ?? "-")
                AppProfileInfoRow(label: "ROLE", value: profile?.role.rawValue.uppercased() ?? "MAINTENANCE")
                AppProfileInfoRow(label: "JOINED", value: joinedDate)
            }
            
            Section {
                Button(action: {
                    store.logout()
                    withAnimation {
                        isLoggedIn = false
                    }
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct MaintenanceProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceProfileView(isLoggedIn: .constant(true))
        }
    }
}
