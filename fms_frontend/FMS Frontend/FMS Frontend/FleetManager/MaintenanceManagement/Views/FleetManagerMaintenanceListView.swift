import SwiftUI

struct FleetManagerMaintenanceListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var searchText = ""
    @State private var showingAddPersonnel = false
    
    // Grid layout for 2 cards per row
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (Matching Drivers Style)
            HStack(spacing: 20) {
                Text("Maintenance Team")
                    .font(.system(size: 20, weight: .black))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name or email...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: { showingAddPersonnel = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Personnel")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .cornerRadius(8)
                }
            }
            .padding(25)
            .background(Color.white)
            
            // MARK: - Grid Content
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredPersonnel) { person in
                        MaintenancePersonnelCard(person: person)
                    }
                }
                .padding(25)
                .padding(.bottom, 100)
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddPersonnel) {
            AddMaintenancePersonnelModal()
        }
    }
    
    private var filteredPersonnel: [MaintenancePersonnel] {
        if searchText.isEmpty {
            return dataManager.maintenancePersonnel
        } else {
            return dataManager.maintenancePersonnel.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct MaintenancePersonnelCard: View {
    let person: MaintenancePersonnel
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header: Name
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                Spacer()
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .alert("Delete Personnel?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    dataManager.deleteMaintenancePersonnel(person)
                }
            } message: {
                Text("Are you sure you want to remove \(person.name) from the maintenance team?")
            }
            
            Divider()
            
            // Contact Info
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(icon: "phone.fill", label: "PHONE", value: person.phone)
                InfoRow(icon: "envelope.fill", label: "EMAIL", value: person.email)
                InfoRow(icon: "calendar", label: "DATE OF BIRTH", value: formatDate(person.dob))
            }
            
            Divider()
            
            // Current Assignment
            VStack(alignment: .leading, spacing: 8) {
                Text("CURRENT ASSIGNMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack {
                    if let vehicleID = person.currentAssignment {
                        Image(systemName: "truck.box.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("Vehicle: \(vehicleID)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    } else {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.gray)
                        Text("No Active Assignment")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(person.currentAssignment != nil ? AppTheme.primary.opacity(0.05) : Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .modifier(AppTheme.cardShadow())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 16)
                .font(.system(size: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
    }
}

struct AddMaintenancePersonnelModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var dob = Date()
    @State private var vehicleID = ""
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Maintenance Personnel")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding(25)
            
            ScrollView {
                VStack(spacing: 20) {
                    ModalFormField(label: "Full Name", text: $name)
                    ModalFormField(label: "Phone Number", text: $phone)
                    ModalFormField(label: "Email Address", text: $email)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DATE OF BIRTH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        
                        DatePicker("", selection: $dob, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    ModalFormField(label: "Assign Vehicle (ID)", text: $vehicleID)
                    
                    Spacer(minLength: 40)
                    
                    Button(action: {
                        let newPerson = MaintenancePersonnel(
                            name: name,
                            phone: phone,
                            email: email,
                            dob: dob,
                            currentAssignment: vehicleID.isEmpty ? nil : vehicleID
                        )
                        dataManager.addMaintenancePersonnel(newPerson)
                        dismiss()
                    }) {
                        Text("Save Personnel")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isFormValid ? AppTheme.primary : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
                .padding(25)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color.white)
    }
}

#Preview {
    FleetManagerMaintenanceListView()
        .environmentObject(FleetDataManager())
}
