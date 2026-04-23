//
//  LoginGridView.swift
//  FMS Frontend
//

import SwiftUI

struct LoginGridView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 40
                for x in stride(from: 0, through: geo.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, through: geo.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(AppColors.primary.opacity(0.04), lineWidth: 1)
        }
    }
}
