import SwiftUI

struct VehicleLogView: View {
    let vehicle: Vehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(AppColors.primary)
                }
                
                Spacer()
                
                Text(vehicle.id)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // Placeholder for Export
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(AppColors.primary)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TRIP LOGS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        Text("Deployment History")
                            .font(.system(size: 32, weight: .black))
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        ForEach(vehicle.history) { trip in
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text(trip.date ?? "Unknown Date")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Text("COMPLETED")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppColors.activeGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppColors.activeGreen.opacity(0.1))
                                        .cornerRadius(6)
                                }
                                
                                HStack(spacing: 20) {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.05))
                                            .frame(width: 40, height: 40)
                                            .overlay(Image(systemName: "arrow.up.right").foregroundColor(AppColors.primary))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("ORIGIN")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.origin)
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.gray.opacity(0.3))
                                    
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.05))
                                            .frame(width: 40, height: 40)
                                            .overlay(Image(systemName: "mappin.and.ellipse").foregroundColor(.gray))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("DESTINATION")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.destination)
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(trip.distance ?? "")
                                            .font(.system(size: 16, weight: .bold))
                                        Text(trip.duration ?? "")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.white)
                            .cornerRadius(16)
                            .modifier(AppColors.cardShadow())
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
    }
}
