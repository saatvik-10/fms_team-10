//
//  LowStockPartsView.swift
//  FMS Frontend
//

import SwiftUI

struct LowStockPartsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Low Stock Parts details will be shown here.")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Low Stock Parts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LowStockPartsView()
    }
}
