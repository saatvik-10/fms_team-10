//
//  DrowsinessAlertView.swift
//  FMS Frontend
//
//  Created by Mrunal Aralkar on 22/04/26.
//

import SwiftUI

struct DrowsinessAlertView: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.red.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)

                Text("⚠️ Drowsiness Detected!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Please pull over safely and take a break.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: onDismiss) {
                    Text("I'm Alert Now")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
        }
    }
}
