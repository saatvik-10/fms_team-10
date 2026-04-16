import SwiftUI

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
                .foregroundColor(.black)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus")
                    Text(buttonTitle)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.black)
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
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            HStack {
                TextField("", text: $text)
                    .font(.system(size: 15, weight: .medium))
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

// MARK: - Add Driver Modal (MATCH IMAGE)
struct DriverModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var licenseNumber = ""
    @State private var expiryDate = ""
    @State private var vehicleClasses = ""
    @State private var showingScanner = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            HStack {
                Text("Add Driver")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Section 1: License Verification
                    VStack(alignment: .leading, spacing: 15) {
                        Text("LICENSE VERIFICATION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        OCRUploadArea(
                            title: "Upload Driver License",
                            subtitle: "Drag and drop or tap to scan document",
                            buttonTitle: "Upload License",
                            action: { showingScanner = true }
                        )
                    }
                    
                    // Section 2: Review Details
                    VStack(alignment: .leading, spacing: 20) {
                        Text("REVIEW DRIVER DETAILS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Full Name", text: $fullName)
                            ModalFormField(label: "License Number", text: $licenseNumber)
                        }
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Expiry Date", text: $expiryDate)
                            ModalFormField(label: "Vehicle Classes", text: $vehicleClasses)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Footer Buttons
            HStack(spacing: 15) {
                Button(action: { dismiss() }) {
                    HStack {
                        Text("Save Driver")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(30)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { name, id, date, classes in
                self.fullName = name
                self.licenseNumber = id
                self.expiryDate = date
                self.vehicleClasses = classes
            }
        }
    }
}

// MARK: - Add Vehicle Modal (MATCH IMAGE)
struct AddVehicleModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var make = ""
    @State private var model = ""
    @State private var regNumber = ""
    @State private var vin = ""
    @State private var showingScanner = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            HStack {
                Text("Add Vehicle")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Section 1: RC Verification
                    VStack(alignment: .leading, spacing: 15) {
                        Text("VEHICLE REGISTRATION (RC) VERIFICATION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        OCRUploadArea(
                            title: "Upload RC Document",
                            subtitle: "Drag and drop or tap to scan document",
                            buttonTitle: "Upload Document",
                            action: { showingScanner = true }
                        )
                    }
                    
                    // Section 2: Review Details
                    VStack(alignment: .leading, spacing: 20) {
                        Text("REVIEW VEHICLE DETAILS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Vehicle Make", text: $make)
                            ModalFormField(label: "Vehicle Model", text: $model)
                        }
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Registration Number", text: $regNumber)
                            ModalFormField(label: "Chassis Number / VIN", text: $vin)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Footer Buttons
            HStack(spacing: 15) {
                Button(action: { dismiss() }) {
                    HStack {
                        Text("Save Vehicle")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(30)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { make, model, reg, vin in
                self.make = "TATA MOTORS"
                self.model = "PRIMA G.35 K"
                self.regNumber = "MH-12-XY-1234"
                self.vin = "4G2BM5..."
            }
        }
    }
}

// MARK: - New Order / Add Trip Modal (MATCH IMAGE)
struct OrderModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fromLocation = "HQ Distribution Center, North"
    @State private var toLocation = "Port Authority"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("New Order")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button("Create") { dismiss() }
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(25)
            .foregroundColor(.black)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 1. Route Details
                    VStack(alignment: .leading, spacing: 15) {
                        Label("ROUTE DETAILS", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.system(size: 14, weight: .bold))
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "FROM", text: $fromLocation)
                            ModalFormField(label: "TO", text: $toLocation)
                        }
                    }
                    
                    // 2. Vehicle Assignment
                    VStack(alignment: .leading, spacing: 15) {
                        Label("VEHICLE ASSIGNMENT", systemImage: "truck.box.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("SELECTED VEHICLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "truck.box.fill")
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("TRK-9042")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Heavy Duty Freightliner • Available")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 3. Calculation Card
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ESTIMATED FUEL COST")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("₹145.20")
                                        .font(.system(size: 38, weight: .black))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Dist: 120mi • 8mpg • ₹3.50/gal")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CO2 IMPACT")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("0.42 Tons")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("ETA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("2h 45m")
                                        .font(.system(size: 14, weight: .bold))
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
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("Create Order")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        Text("Complete all mandatory fields to finalize dispatch")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(30)
            }
        }
        .background(Color.white)
    }
}
