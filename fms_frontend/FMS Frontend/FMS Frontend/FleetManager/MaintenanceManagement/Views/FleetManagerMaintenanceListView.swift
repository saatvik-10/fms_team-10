import SwiftUI

struct FleetManagerMaintenanceListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var searchText = ""
    @State private var showingAddPersonnel = false
    @State private var isLoadingPersonnel = false
    @State private var loadError: String?
    
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
                if isLoadingPersonnel && filteredPersonnel.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading maintenance team...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else if filteredPersonnel.isEmpty {
                    VStack(spacing: 10) {
                        Text(emptyStateTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                        Text(emptyStateSubtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 25)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredPersonnel) { person in
                            MaintenancePersonnelCard(person: person)
                        }
                    }
                    .padding(25)
                    .padding(.bottom, 100)
                }
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddPersonnel) {
            AddMaintenancePersonnelModal()
        }
        .task {
            await loadPersonnel()
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

    private var emptyStateTitle: String {
        searchText.isEmpty ? "No maintenance personnel yet" : "No matching personnel found"
    }

    private var emptyStateSubtitle: String {
        if let loadError {
            return loadError
        }
        return searchText.isEmpty
            ? "No profiles available right now. Add personnel to get started."
            : "Try a different name or email to find personnel."
    }

    private func loadPersonnel() async {
        isLoadingPersonnel = true
        loadError = nil

        defer {
            isLoadingPersonnel = false
        }

        do {
            try await dataManager.refreshMaintenancePersonnel()
        } catch {
            loadError = "Maintenance profiles could not be loaded right now."
        }
    }
    
    func deletePerson(_ person: MaintenancePersonnel) async {
        await dataManager.deleteMaintenancePersonnel(person)
    }
}

struct MaintenancePersonnelCard: View {
    let person: MaintenancePersonnel
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
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
                .disabled(isDeleting)
            }
            .alert("Delete Personnel?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    isDeleting = true
                    Task {
                        await deletePerson()
                    }
                }
            } message: {
                Text("Are you sure you want to remove \(person.name) from the maintenance team?")
            }

            Divider()

            // Contact Info
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(icon: "phone.fill", label: "PHONE", value: person.phone)
                InfoRow(icon: "envelope.fill", label: "EMAIL", value: person.email)
                InfoRow(icon: "calendar", label: "AGE", value: displayAge)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .modifier(AppTheme.cardShadow())
    }
    
    private func deletePerson() async {
        await dataManager.deleteMaintenancePersonnel(person)
        isDeleting = false
    }

    private var displayAge: String {
        if let age = person.age {
            return "\(age)"
        }
        let years = Calendar.current.dateComponents([.year], from: person.dob, to: Date()).year
        return years.map(String.init) ?? "To be integrated"
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
    @State private var isLoading = false
    
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
                    
                    Spacer(minLength: 40)
                    
                    Button(action: {
                        savePersonnel()
                    }) {
                        Text(isLoading ? "Saving..." : "Save Personnel")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isFormValid ? AppTheme.primary : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .padding(25)
            }
        }
    }
    
    private func savePersonnel() {
        guard isFormValid else { return }
        isLoading = true
        
        let formatter = ISO8601DateFormatter()
        let dobString = formatter.string(from: dob)
        
        Task {
            do {
                let request = CreateMaintenanceRequest(
                    name: name,
                    dob: dobString,
                    email: email,
                    phone: phone
                )
                let response = try await MaintenanceAPI.shared.createMaintenanceProfile(request)

                let createdPerson = MaintenancePersonnel(
                    backendId: response.maintenance.id,
                    name: response.maintenance.name ?? name,
                    phone: response.maintenance.phone ?? phone,
                    email: response.maintenance.email ?? email,
                    dob: response.maintenance.dob ?? dob,
                    age: response.maintenance.age,
                    currentAssignment: nil
                )

                await MainActor.run {
                    dataManager.addMaintenancePersonnel(createdPerson)
                }

                // Try to sync with backend list if endpoint is available.
                try? await dataManager.refreshMaintenancePersonnel()
                dismiss()
            } catch {
                isLoading = false
            }
        }
    }
}

#Preview {
    FleetManagerMaintenanceListView()
        .environmentObject(FleetDataManager())
}
