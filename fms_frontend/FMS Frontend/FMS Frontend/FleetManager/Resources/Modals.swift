import MapKit
import SwiftUI
import Combine
import PhotosUI
internal import UIKit

// MARK: - Premium Modal Components

struct OCRUploadArea: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(AppFonts.headline)
                Text(subtitle)
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus")
                    Text(buttonTitle)
                }
                .font(AppFonts.button)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(AppTheme.primary)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(Color.gray.opacity(0.4))
        )
    }
}

struct ModalFormField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(AppFonts.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            HStack {
                TextField("", text: $text)
                    .font(AppFonts.subheadline)
                    .minimumScaleFactor(0.5)
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct ModalSearchField: View {
    let label: String
    @Binding var text: String
    @StateObject private var completer = LocationSearchCompleter()
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(AppFonts.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search location...", text: $text, onEditingChanged: { editing in
                        isEditing = editing
                        if editing { completer.searchQuery = text }
                    })
                    .onChange(of: text) { _, newValue in
                        completer.searchQuery = newValue
                    }
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if isEditing && !completer.completions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(completer.completions, id: \.title) { completion in
                                Button(action: {
                                    text = "\(completion.title), \(completion.subtitle)"
                                    isEditing = false
                                    // hide keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(completion.title).font(AppFonts.headline).foregroundColor(AppTheme.textPrimary)
                                        if !completion.subtitle.isEmpty {
                                            Text(completion.subtitle).font(AppFonts.caption1).foregroundColor(.gray)
                                        }
                                        Divider()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(10)
                    .modifier(AppTheme.cardShadow())
                    .offset(y: 5)
                }
            }
            .zIndex(isEditing ? 1 : 0)
        }
    }
}

// MARK: - Add Driver Modal (MATCH IMAGE)
struct DriverModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    let driverToEdit: Driver?

    private static let vehicleClassOptions: [String] = [
        "LMV-NT",
        "LMV-TR",
        "LMV-GV",
        "MCWG",
        "TRANS",
        "LPV",
        "MGV",
        "MPV",
        "HGV",
        "HPV",
        "HGMV",
        "HPMV",
        "HTV"
    ]
    
    private static let ocrToFormClass: [String: String] = [
        "LMV": "LMV-NT",
        "MCWG": "MCWG",
        "HMV": "HGV",
        "LMVTR": "LMV-TR",
        "TR": "LMV-TR",
        "TRANS": "TRANS",
        "LMVTRANS": "LMV-TR"
    ]
    
    @State private var fullName: String
    @State private var email: String = ""
    @State private var licenseNumber: String
    @State private var expiryDate: String
    @State private var phone: String
    @State private var vehicleClasses: [String] = [Self.vehicleClassOptions.first ?? "LMV-NT"] // Support multiple classes
    @State private var showingScanner = false
    @State private var licenseError: String? = nil
    @State private var emailError: String? = nil
    @State private var frontLicenseImageData: Data?
    @State private var backLicenseImageData: Data?
    @State private var isSaving = false
    @State private var saveError: String? = nil

    init(driverToEdit: Driver? = nil) {
        self.driverToEdit = driverToEdit
        let validExistingClasses = (driverToEdit?.vehicleClasses ?? []).filter { Self.vehicleClassOptions.contains($0) }
        _fullName = State(initialValue: driverToEdit?.name ?? "")
        _email = State(initialValue: driverToEdit?.email ?? "")
        _licenseNumber = State(initialValue: driverToEdit?.licenseNum ?? "")
        _expiryDate = State(initialValue: driverToEdit?.licenseExp ?? "")
        _phone = State(initialValue: driverToEdit?.phone ?? "+91 ")
        _vehicleClasses = State(initialValue: validExistingClasses.isEmpty ? [Self.vehicleClassOptions.first ?? "LMV-NT"] : validExistingClasses)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    
    var body: some View {
        NavigationView {
            Form {
                if driverToEdit == nil {
                    Section(header: Text("License Verification")) {
                        OCRUploadArea(
                            title: "Upload Driver License",
                            subtitle: "Drag and drop or tap to scan document",
                            buttonTitle: "Upload License",
                            action: { showingScanner = true }
                        )
                        if frontLicenseImageData != nil || backLicenseImageData != nil {
                            HStack(spacing: 12) {
                                Label(frontLicenseImageData != nil ? "Front uploaded" : "Front missing", systemImage: frontLicenseImageData != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(frontLicenseImageData != nil ? .green : .orange)
                                Label(backLicenseImageData != nil ? "Back uploaded" : "Back missing", systemImage: backLicenseImageData != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(backLicenseImageData != nil ? .green : .orange)
                            }
                            .font(AppFonts.caption2)
                        }
                    }
                } else {
                    Section(header: Text("License Verification")) {
                        Text("License images are already stored. Update the text fields below to edit the driver profile.")
                            .font(AppFonts.caption1)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Driver Details")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Phone Number", text: $phone)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { _, newValue in
                                if newValue.isEmpty {
                                    emailError = nil
                                } else if !isValidEmail(newValue) {
                                    emailError = "Enter a valid email address"
                                } else {
                                    emailError = nil
                                }
                            }
                        if let error = emailError {
                            Text(error)
                                .font(AppFonts.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("License Number", text: $licenseNumber)
                            .onChange(of: licenseNumber) { _, newValue in
                                if newValue.count != 15 && !newValue.isEmpty {
                                    licenseError = "License number must be 15 characters"
                                } else {
                                    licenseError = nil
                                }
                            }
                        if let error = licenseError {
                            Text(error)
                                .font(AppFonts.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    TextField("Expiry Date", text: $expiryDate)
                }
                
                Section(header: Text("Vehicle Classes")) {
                    ForEach(0..<vehicleClasses.count, id: \.self) { index in
                        HStack {
                            Picker("Class \(index + 1)", selection: $vehicleClasses[index]) {
                                ForEach(Self.vehicleClassOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            if vehicleClasses.count > 1 {
                                Button(role: .destructive, action: { vehicleClasses.remove(at: index) }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    
                    Button(action: { vehicleClasses.append(Self.vehicleClassOptions.first ?? "LMV-NT") }) {
                        Label("Add Class", systemImage: "plus")
                    }
                }
                
                Section {
                    Button(action: {
                        Task { await saveDriver() }
                    }) {
                        Text(isSaving ? "Saving..." : (driverToEdit == nil ? "Save Driver" : "Update Driver"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.bold)
                            .foregroundColor(canSave ? .white : .gray)
                    }
                    .listRowBackground(canSave ? AppTheme.primary : Color(.systemGroupedBackground))
                    .disabled(isSaving || !canSave)
                }
                
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundColor(.red)
                            .font(AppFonts.caption2)
                    }
                }
            }
            .navigationTitle(driverToEdit == nil ? "Add Driver" : "Update Driver")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { name, id, date, vehicles, frontImage, backImage in
                self.fullName = name
                self.licenseNumber = id
                self.expiryDate = date
                self.frontLicenseImageData = frontImage
                self.backLicenseImageData = backImage
                // Split vehicles by comma, slash, space, or newline if multiple detected
                let separators = CharacterSet(charactersIn: ",/& \n\t")
                var detected: [String] = []
                let parts = vehicles.components(separatedBy: separators)
                for part in parts {
                    let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    // Check if it's a direct match or needs mapping
                    if Self.vehicleClassOptions.contains(trimmed) {
                        if !detected.contains(trimmed) { detected.append(trimmed) }
                    } else if let mapped = Self.ocrToFormClass[trimmed] {
                        if !detected.contains(mapped) { detected.append(mapped) }
                    }
                }
                self.vehicleClasses = detected.isEmpty ? [Self.vehicleClassOptions.first ?? "LMV-NT"] : detected
            }
        }
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !expiryDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (driverToEdit != nil || (frontLicenseImageData != nil && backLicenseImageData != nil))
    }

    private func saveDriverLocally() {
        let validVehicleClasses = vehicleClasses.filter { Self.vehicleClassOptions.contains($0) }
        let selectedVehicleClasses = validVehicleClasses.reduce(into: [String]()) { result, item in
            if !result.contains(item) {
                result.append(item)
            }
        }
        let finalVehicleClasses = selectedVehicleClasses.isEmpty ? [Self.vehicleClassOptions.first ?? "LMV-NT"] : selectedVehicleClasses
        let newDriverID = driverToEdit?.id ?? "KM-\(Int.random(in: 1000...9999))"
        let newDriver = Driver(
            id: newDriverID,
            backendId: driverToEdit?.backendId,
            name: fullName,
            email: email,
            title: "\(finalVehicleClasses.first ?? "LMV-NT") Certified Driver",
            licenseNum: licenseNumber,
            licenseExp: expiryDate,
            status: .offDuty,
            rating: 5.0,
            efficiency: "100%",
            totalTrips: 0,
            totalHours: 0,
            activityLog: [],
            currentVehicleID: nil,
            vehicleClasses: finalVehicleClasses,
            activeRoute: nil,
            eta: nil,
            phone: phone,
            dlFrontImageUrl: driverToEdit?.dlFrontImageUrl,
            dlBackImageUrl: driverToEdit?.dlBackImageUrl,
            dlFrontImageKey: driverToEdit?.dlFrontImageKey,
            dlBackImageKey: driverToEdit?.dlBackImageKey
        )
        DriverEmailStore.shared.saveEmail(email, forDriverID: newDriverID)
        dataManager.upsertDriver(newDriver)
        dismiss()
    }

    private func saveDriver() async {
        saveError = nil
        guard canSave else {
            saveError = "Please complete all fields and upload both DL images."
            return
        }

        let validVehicleClasses = vehicleClasses.filter { Self.vehicleClassOptions.contains($0) }
        let selectedVehicleClasses = validVehicleClasses.reduce(into: [String]()) { result, item in
            if !result.contains(item) {
                result.append(item)
            }
        }
        let finalVehicleClasses = selectedVehicleClasses.isEmpty ? [Self.vehicleClassOptions.first ?? "LMV-NT"] : selectedVehicleClasses

        let request = CreateDriverRequest(
            fullName: fullName,
            email: email,
            phone: phone,
            licenseNumber: licenseNumber,
            expiryDate: expiryDate,
            classes: finalVehicleClasses,
            licenseFrontImage: frontLicenseImageData ?? Data(),
            licenseBackImage: backLicenseImageData ?? Data()
        )

        if let editingDriver = driverToEdit {
            await updateDriver(editingDriver, finalVehicleClasses: finalVehicleClasses)
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await DriverAPI.shared.createDriverProfile(request)
            let newDriverID = "KM-\(Int.random(in: 1000...9999))"
            let newDriver = Driver(
                id: newDriverID,
                backendId: response.driver.id,
                name: response.driver.name ?? fullName,
                email: response.driver.email ?? email,
                title: "\(finalVehicleClasses.first ?? "LMV-NT") Certified Driver",
                licenseNum: response.driver.licenceNumber ?? licenseNumber,
                licenseExp: response.driver.expiryDate ?? expiryDate,
                status: .offDuty,
                rating: 5.0,
                efficiency: "100%",
                totalTrips: 0,
                totalHours: 0,
                activityLog: [],
                currentVehicleID: nil,
                vehicleClasses: response.driver.classes ?? finalVehicleClasses,
                activeRoute: nil,
                eta: nil,
                phone: response.driver.phone ?? phone,
                dlFrontImageUrl: response.driver.dlFrontImageUrl,
                dlBackImageUrl: response.driver.dlBackImageUrl,
                dlFrontImageKey: response.driver.dlFrontImageKey,
                dlBackImageKey: response.driver.dlBackImageKey
            )

            await MainActor.run {
                DriverEmailStore.shared.saveEmail(email, forDriverID: response.driver.id ?? newDriverID)
                dataManager.upsertDriver(newDriver)
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
            }
        }
    }

    private func updateDriver(_ editingDriver: Driver, finalVehicleClasses: [String]) async {
        guard let backendId = editingDriver.backendId else {
            saveDriverLocally()
            return
        }

        isSaving = true
        defer { isSaving = false }

        let request = UpdateDriverRequest(
            fullName: fullName,
            email: email,
            phone: phone,
            licenseNumber: licenseNumber,
            expiryDate: expiryDate,
            classes: finalVehicleClasses
        )

        do {
            let response = try await DriverAPI.shared.updateDriverProfile(id: backendId, request: request)
            let updatedDriver = Driver(
                id: editingDriver.id,
                backendId: response.driver.id ?? backendId,
                name: response.driver.name ?? fullName,
                email: response.driver.email ?? email,
                title: "\(finalVehicleClasses.first ?? "LMV-NT") Certified Driver",
                licenseNum: response.driver.licenceNumber ?? licenseNumber,
                licenseExp: response.driver.expiryDate ?? expiryDate,
                status: editingDriver.status,
                rating: editingDriver.rating,
                efficiency: editingDriver.efficiency,
                totalTrips: editingDriver.totalTrips,
                totalHours: editingDriver.totalHours,
                activityLog: editingDriver.activityLog,
                currentVehicleID: editingDriver.currentVehicleID,
                vehicleClasses: response.driver.classes ?? finalVehicleClasses,
                activeRoute: editingDriver.activeRoute,
                eta: editingDriver.eta,
                phone: response.driver.phone ?? phone,
                dlFrontImageUrl: editingDriver.dlFrontImageUrl,
                dlBackImageUrl: editingDriver.dlBackImageUrl,
                dlFrontImageKey: editingDriver.dlFrontImageKey,
                dlBackImageKey: editingDriver.dlBackImageKey
            )

            await MainActor.run {
                DriverEmailStore.shared.saveEmail(email, forDriverID: backendId)
                dataManager.upsertDriver(updatedDriver)
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
            }
        }
    }
}

// MARK: - Add Vehicle Modal (MATCH IMAGE)
struct AddVehicleModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    let vehicleToEdit: Vehicle?
    
    @State private var make: String
    @State private var model: String
    @State private var regNumber: String
    @State private var vin: String
    @State private var maxLoadCapacity: String = "0"
    @State private var capacityUnit: String = "KG"
    @State private var showingScanner = false
    @State private var rcDocumentImageData: Data?
    @State private var isSaving = false
    @State private var saveError: String? = nil

    // VEHICLE IMAGE STATE
    @State private var selectedVehicleImage: UIImage?
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false



    
    init(vehicleToEdit: Vehicle? = nil) {
        self.vehicleToEdit = vehicleToEdit
        _make = State(initialValue: vehicleToEdit?.make ?? "")
        _model = State(initialValue: vehicleToEdit?.model ?? "")
        _regNumber = State(initialValue: vehicleToEdit?.registrationNumber ?? "")
        _vin = State(initialValue: vehicleToEdit?.chassisNumber ?? "")
        _maxLoadCapacity = State(initialValue: String(format: "%.0f", vehicleToEdit?.maxLoadCapacity ?? 0))
        _capacityUnit = State(initialValue: vehicleToEdit?.capacityUnit ?? "KG")
    }

    private var canSave: Bool {
        let hasVehicleImage = selectedVehicleImage != nil || vehicleToEdit?.vehicleImageUrl != nil
        let hasRcImage = rcDocumentImageData != nil || vehicleToEdit?.rcImageUrl != nil

        return !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !regNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !vin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !(Double(maxLoadCapacity) ?? 0 <= 0) &&
            hasVehicleImage && hasRcImage
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("RC Verification")) {
                    OCRUploadArea(
                        title: "Upload RC Document",
                        subtitle: "Drag and drop or tap to scan document",
                        buttonTitle: "Upload Document",
                        action: { showingScanner = true }
                    )

                    if rcDocumentImageData != nil || vehicleToEdit?.rcImageUrl != nil {
                        Label("RC document ready", systemImage: "checkmark.circle.fill")
                            .font(AppFonts.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Vehicle Image")) {
                    VStack(spacing: 15) {
                        if let image = selectedVehicleImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .clipped()
                                .onTapGesture {
                                    showActionSheet = true
                                }
                        } else if let urlString = vehicleToEdit?.vehicleImageUrl, let url = URL(string: urlString) {
                            asyncImageView(url: url)
                        } else {
                            placeholderUploadArea
                        }
                    }

                    if selectedVehicleImage != nil || vehicleToEdit?.vehicleImageUrl != nil {
                        Label("Vehicle image ready", systemImage: "checkmark.circle.fill")
                            .font(AppFonts.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Vehicle Details")) {
                    TextField("Vehicle Owner", text: $make)
                    TextField("Vehicle Model", text: $model)
                    TextField("Registration Number", text: $regNumber)
                    TextField("Chassis Number / VIN", text: $vin)
                }
                
                Section(header: Text("Capacity Load")) {
                    HStack {
                        TextField("0.0", text: $maxLoadCapacity)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $capacityUnit) {
                            Text("KG").tag("KG")
                            Text("Tons").tag("Tons")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }
                
                Section {
                    Button(action: {
                        Task { await saveVehicle() }
                    }) {
                        Text(isSaving ? "Saving..." : (vehicleToEdit == nil ? "Save Vehicle" : "Update Vehicle"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.bold)
                            .foregroundColor(canSave ? .white : .gray)
                    }
                    .listRowBackground(canSave ? AppTheme.primary : Color(.systemGroupedBackground))
                    .disabled(isSaving || !canSave)
                }
                
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundColor(.red)
                            .font(AppFonts.caption2)
                    }
                }
            }
            .navigationTitle(vehicleToEdit == nil ? "Add Vehicle" : "Update Vehicle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Select Image Source"),
                message: Text("Take photo or choose from gallery"),
                buttons: [
                    .default(Text("Take Photo")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            imageSourceType = .camera
                            showImagePicker = true
                        }
                    },
                    .default(Text("Choose from Gallery")) {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            VehicleAppImagePicker(sourceType: imageSourceType, selectedImage: $selectedVehicleImage)
        }
        .sheet(isPresented: $showingScanner) {
            RCScannerView(isPresented: $showingScanner) { owner, reg, model, chassis, imageData in
                self.regNumber = reg
                self.model = model
                self.vin = chassis
                self.rcDocumentImageData = imageData
                if !owner.isEmpty {
                    self.make = owner
                }
            }
        }
    }

    private func saveVehicle() async {
        saveError = nil

        guard canSave else {
            saveError = "Please fill all fields and upload both RC and vehicle images."
            return
        }

        if let editingVehicle = vehicleToEdit {
            await updateVehicle(editingVehicle)
            return
        }

        // Process images if provided (optional but supported)
        var rcBase64: String? = nil
        if let rcData = rcDocumentImageData {
            rcBase64 = rcData.base64EncodedString()
        }
        var vehicleBase64: String? = nil
        if let vImg = selectedVehicleImage?.jpegData(compressionQuality: 0.7) {
            vehicleBase64 = vImg.base64EncodedString()
        }

        let request = CreateVehicleRequest(
            make: make,
            model: model,
            type: "Truck",
            status: nil,
            imageName: nil,
            year: nil,
            color: nil,
            operationalStatus: nil,
            assessmentReason: nil,
            chassisNumber: vin,
            registrationNumber: regNumber,
            rcDocumentImage: rcBase64,
            vehicleImage: vehicleBase64,
            maxLoadCapacity: Double(maxLoadCapacity) ?? 0,
            capacityUnit: capacityUnit
        )

        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await VehicleAPI.shared.createVehicleProfile(request)
            let newVehicle = Vehicle(
                id: response.vehicle.registrationNumber,
                backendId: response.vehicle.id,
                make: response.vehicle.make,
                model: response.vehicle.model,
                type: response.vehicle.type,
                status: VehicleStatus(rawValue: response.vehicle.status) ?? .idle,
                imageName: response.vehicle.imageName ?? "truck_freightliner_m2",
                year: response.vehicle.year ?? "-",
                color: response.vehicle.color ?? "-",
                operationalStatus: response.vehicle.operationalStatus ?? "OPERATIONAL",
                currentTrip: nil,
                assignedDriver: nil,
                maintenance: VehicleMaintenance(nextService: "TBD", inspectionStatus: "Verified", alerts: []),
                history: [],
                reports: [],
                assessmentReason: response.vehicle.assessmentReason,
                chassisNumber: response.vehicle.chassisNumber,
                registrationNumber: response.vehicle.registrationNumber,
                rcImageUrl: response.vehicle.rcImageUrl,
                vehicleImageUrl: response.vehicle.vehicleImageUrl,
                maxLoadCapacity: response.vehicle.maxLoadCapacity ?? (Double(maxLoadCapacity) ?? 0),
                capacityUnit: response.vehicle.capacityUnit ?? capacityUnit
            )

            await MainActor.run {
                dataManager.upsertVehicle(newVehicle)
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
            }
        }
    }

    private func updateVehicle(_ editingVehicle: Vehicle) async {
        guard let backendId = editingVehicle.backendId else {
            saveError = "Vehicle ID is missing for update."
            return
        }

        var rcBase64: String? = nil
        if let rcData = rcDocumentImageData {
            rcBase64 = rcData.base64EncodedString()
        }
        var vehicleBase64: String? = nil
        if let vImg = selectedVehicleImage?.jpegData(compressionQuality: 0.7) {
            vehicleBase64 = vImg.base64EncodedString()
        }

        let request = UpdateVehicleRequest(
            make: make,
            model: model,
            type: "Truck",
            status: nil,
            imageName: nil,
            year: nil,
            color: nil,
            operationalStatus: nil,
            assessmentReason: nil,
            chassisNumber: vin,
            registrationNumber: regNumber,
            rcDocumentImage: rcBase64,
            vehicleImage: vehicleBase64,
            assignedDriverId: nil,
            maxLoadCapacity: Double(maxLoadCapacity) ?? 0,
            capacityUnit: capacityUnit
        )

        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await VehicleAPI.shared.updateVehicleProfile(id: backendId, request: request)
            let vehicleStatus = VehicleStatus(rawValue: response.vehicle.status) ?? editingVehicle.status
            let updatedVehicle = Vehicle(
                id: response.vehicle.registrationNumber,
                backendId: response.vehicle.id,
                make: response.vehicle.make,
                model: response.vehicle.model,
                type: response.vehicle.type,
                status: vehicleStatus,
                imageName: response.vehicle.imageName ?? editingVehicle.imageName,
                year: response.vehicle.year ?? editingVehicle.year,
                color: response.vehicle.color ?? editingVehicle.color,
                operationalStatus: response.vehicle.operationalStatus ?? editingVehicle.operationalStatus,
                currentTrip: editingVehicle.currentTrip,
                assignedDriver: editingVehicle.assignedDriver,
                maintenance: editingVehicle.maintenance,
                history: editingVehicle.history,
                reports: editingVehicle.reports,
                assessmentReason: response.vehicle.assessmentReason,
                chassisNumber: response.vehicle.chassisNumber,
                registrationNumber: response.vehicle.registrationNumber,
                rcImageUrl: response.vehicle.rcImageUrl ?? editingVehicle.rcImageUrl,
                vehicleImageUrl: response.vehicle.vehicleImageUrl ?? editingVehicle.vehicleImageUrl,
                maxLoadCapacity: response.vehicle.maxLoadCapacity ?? (Double(maxLoadCapacity) ?? 0),
                capacityUnit: response.vehicle.capacityUnit ?? capacityUnit
            )

            await MainActor.run {
                dataManager.upsertVehicle(updatedVehicle)
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
            }
        }
    }

    private var placeholderUploadArea: some View {
        VStack(spacing: 15) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            VStack(spacing: 4) {
                Text("Upload Vehicle Image")
                    .font(.system(size: 16, weight: .bold))
                Text("Take photo or choose from gallery")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Button(action: { showActionSheet = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Image")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(AppTheme.primary)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    @ViewBuilder
    private func asyncImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .clipped()
                    .onTapGesture {
                        showActionSheet = true
                    }
            } else if phase.error != nil {
                placeholderUploadArea
            } else {
                ProgressView().tint(AppTheme.primary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Local ImagePicker Helper
struct VehicleAppImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VehicleAppImagePicker
        init(_ parent: VehicleAppImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.selectedImage = image }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - New Order / Add Trip Modal (MATCH IMAGE)
struct OrderModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @State private var selectedVehicleID = ""
    @State private var productName = ""
    @State private var loadAmount = ""
    @State private var loadUnit = "Tons"
    @State private var ownerName = ""
    @State private var phoneNum = ""
    @State private var showingScanner = false
    
    private let unitOptions = ["Tons", "KG", "Liters", "Units", "Pallets"]

    // Dynamic estimation logic
    private var estimatedDistance: Int {
        if fromLocation.isEmpty && toLocation.isEmpty { return 0 }
        return max(45, (fromLocation.count + toLocation.count) * 12)
    }
    
    private var estimatedCost: Double {
        if estimatedDistance == 0 { return 0.0 }
        return max(75.50, Double(estimatedDistance) * 1.5 + 25.0)
    }

    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Order")
                    .font(AppFonts.title1)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(AppFonts.title3)
                }
            }
            .padding(25)
            .foregroundColor(AppTheme.primary)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 1. Route Details
                    VStack(alignment: .leading, spacing: 15) {
                        Label("ROUTE DETAILS", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            ModalSearchField(label: "FROM", text: $fromLocation)
                            ModalSearchField(label: "TO", text: $toLocation)
                        }
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "PRODUCT TYPE", text: $productName)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("LOAD AMOUNT")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 0) {
                                    TextField("0.0", text: $loadAmount)
                                        .keyboardType(.decimalPad)
                                        .padding(12)
                                        .background(AppTheme.secondaryBackground)
                                        .cornerRadius(8)
                                    
                                    Menu {
                                        ForEach(unitOptions, id: \.self) { unit in
                                            Button(unit) { loadUnit = unit }
                                        }
                                    } label: {
                                        HStack {
                                            Text(loadUnit)
                                                .font(AppFonts.caption2)
                                                .fontWeight(.bold)
                                            Image(systemName: "chevron.down")
                                                .font(AppFonts.caption2)
                                        }
                                        .foregroundColor(AppTheme.primary)
                                        .padding(.horizontal, 12)
                                        .frame(height: 44)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                                    }
                                }
                            }
                        }
                    }
                    
                    // 2. Vehicle Assignment
                    VStack(alignment: .leading, spacing: 15) {
                        Label("VEHICLE ASSIGNMENT", systemImage: "truck.box.fill")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                        
                        Text("SELECTED VEHICLE")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(dataManager.vehicles) { vehicle in
                                Button(action: {
                                    selectedVehicleID = vehicle.id
                                }) {
                                    Text("\(vehicle.id) - \(vehicle.make)")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "truck.box.fill")
                                    .padding()
                                    .background(AppTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text(selectedVehicleID.isEmpty ? "Tap to select vehicle" : selectedVehicleID)
                                        .font(AppFonts.headline)
                                        .foregroundColor(selectedVehicleID.isEmpty ? .gray : AppTheme.textPrimary)
                                    Text("Available for dispatch")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(.gray)
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 3. Contact Details
                    VStack(alignment: .leading, spacing: 15) {
                        Label("CONTACT DETAILS", systemImage: "person.crop.circle.badge.checkmark")
                            .font(AppFonts.headline)
                            .fontWeight(.bold)
                        
                        ModalFormField(label: "PHONE NUMBER", text: $phoneNum)
                    }
                    
                    // 4. Calculation Card
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ESTIMATED FUEL COST")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Text(String(format: "$%.2f", estimatedCost))
                                        .font(AppFonts.largeTitle)
                                        .fontWeight(.black)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Dist: 120mi • 8mpg • ₹3.50/gal")
                                        .font(AppFonts.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CO2 IMPACT")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Text("0.42 Tons")
                                        .font(AppFonts.subheadline)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("ETA")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Text("2h 45m")
                                        .font(AppFonts.headline)
                                }
                            }
                        }
                        .padding(30)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Bottom Button
                    VStack(spacing: 15) {
                        Button(action: { 
                            let trip = VehicleTrip(
                                vehicleID: selectedVehicleID,
                                origin: fromLocation,
                                destination: toLocation,
                                progress: 0.0,
                                eta: "TBD",
                                date: "Now",
                                distance: "0 mi",
                                duration: "0 hrs",
                                costEstimate: String(format: "₹%.2f", estimatedCost),
                                startTime: Date(),
                                status: .scheduled,
                                productType: productName,
                                loadAmount: "\(loadAmount) \(loadUnit)"
                            )
                            dataManager.addOrder(trip: trip, vehicleID: selectedVehicleID)
                            dismiss() 
                        }) {
                            HStack {
                                Text("Create Order")
                            }
                            .font(AppFonts.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(fromLocation.isEmpty || selectedVehicleID.isEmpty ? Color.gray : AppTheme.primary)
                            .cornerRadius(12)
                        }
                        .disabled(fromLocation.isEmpty || selectedVehicleID.isEmpty)
                        
                        Text("Complete all mandatory fields to finalize dispatch")
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(30)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { name, doc, _, _, _, _ in
                self.ownerName = name
            }
        }
    }
}



class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        
        cancellable = $searchQuery.debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.completions = []
                } else {
                    self?.completer.queryFragment = query
                }
            }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error
    }
}
