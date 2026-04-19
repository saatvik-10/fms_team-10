import SwiftUI
import GoogleMaps

// MARK: - Direction Icon Helper

private func directionIcon(for instruction: String) -> String {
    let lower = instruction.lowercased()
    if lower.contains("u-turn") || lower.contains("uturn") {
        return "arrow.uturn.backward"
    } else if lower.contains("turn left") || lower.contains("keep left") || lower.contains("exit left") {
        return "arrow.turn.up.left"
    } else if lower.contains("turn right") || lower.contains("keep right") || lower.contains("exit right") {
        return "arrow.turn.up.right"
    } else if lower.contains("merge") || lower.contains("continue") || lower.contains("head") {
        return "arrow.up"
    } else if lower.contains("roundabout") || lower.contains("rotary") {
        return "arrow.triangle.2.circlepath"
    } else if lower.contains("destination") || lower.contains("arrive") {
        return "mappin.circle.fill"
    } else {
        return "arrow.up"
    }
}

// MARK: - Top Navigation Banner

private struct NavigationBannerView: View {
    let currentInstruction: String
    let nextInstruction: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Primary instruction row
            HStack(alignment: .center, spacing: 14) {
                // Direction icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: directionIcon(for: currentInstruction))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                // Instruction text
                Text(currentInstruction)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, nextInstruction.isEmpty ? 16 : 12)

            // Divider + next instruction
            if !nextInstruction.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.25))
                    .padding(.horizontal, 16)

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: directionIcon(for: nextInstruction))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(width: 22)

                    Text("Then: \(nextInstruction)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.04, green: 0.56, blue: 0.54)) // Google Maps teal
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Bottom ETA / Distance Card

private struct BottomTrackingCard: View {
    let etaText: String
    let distanceRemaining: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(etaText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("ETA")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text(distanceRemaining)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("DISTANCE")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
    }
}

// MARK: - Main Navigation View

struct CustomNavigationView: View {
    @StateObject private var viewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(trip: Trip) {
        _viewModel = StateObject(wrappedValue: NavigationViewModel(trip: trip))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // Full-screen map
            CustomGoogleMapViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Top overlay
            VStack(spacing: 10) {
                
                // Dismiss button row
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // Navigation instruction banner
                NavigationBannerView(
                    currentInstruction: viewModel.currentInstruction,
                    nextInstruction: viewModel.nextInstruction
                )
            }
            .padding(.top, 16)
        }
        
        // ✅ THIS replaces overlay
        .safeAreaInset(edge: .bottom) {
            BottomTrackingCard(
                etaText: viewModel.etaText,
                distanceRemaining: viewModel.distanceRemaining
            )
            .background(Color.black) // ensures no gap / transparency
        }
        
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.startNavigation()
        }
    }
}

// MARK: - Rounded Corner Shape

private struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
