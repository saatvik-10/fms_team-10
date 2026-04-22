//
//  DrowsinessAlertView.swift
//  FMS Frontend
//

import SwiftUI

struct DrowsinessAlertView: View {
    var onDismiss: () -> Void
    @State private var pulse = false
    @State private var iconScale = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.6, green: 0.0, blue: 0.0),
                         Color(red: 0.2, green: 0.0, blue: 0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)

            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: pulse ? 500 : 300)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                           value: pulse)

            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: pulse ? 350 : 200)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            .delay(0.3), value: pulse)

            VStack(spacing: 0) {

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(iconScale ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: iconScale)
                }
                .padding(.bottom, 36)

                Text("DROWSINESS ALERT")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(4)
                    .padding(.bottom, 10)

                Text("You appear\nto be drowsy")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 16)

                Text("Pull over safely and rest.\nDo not continue driving while fatigued.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)

                Spacer(minLength: 24)

                Button(action: onDismiss) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                        Text("I'm Alert Now")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            pulse = true
            iconScale = true
        }
    }
}
