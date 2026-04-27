//
//  MaintenanceProfileView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceProfileView: View {
    @Binding var isLoggedIn: Bool

    private var profile: UserProfile {
        UserProfile.mockMaintenance
    }

    private var joinedDate: String {
        profile.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppColors.primary)
                    
                    VStack(spacing: 4) {
                        Text(profile.name)
                            .font(.title2.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)

            Section("Account Details") {
                AppProfileInfoRow(label: "USERNAME", value: profile.username)
                AppProfileInfoRow(label: "PHONE", value: profile.phone)
                AppProfileInfoRow(label: "EMAIL", value: profile.email)
                AppProfileInfoRow(label: "ROLE", value: profile.role.rawValue)
                AppProfileInfoRow(label: "JOINED", value: joinedDate)
            }

            Section {
                Button(action: {
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
