//
//  MaintenanceDashboardView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceDashboardView: View {
    @EnvironmentObject var store: MaintenanceStore
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header / Greetings
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fleet Overview")
                        .font(.system(size: 28, weight: .black))
                    Text("Real-time maintenance analytics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)

                // KPI Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    KPICard(
                        title: "PENDING ORDERS",
                        value: "\(store.workOrders.filter { $0.status == .pending }.count)",
                        icon: "clock.badge.exclamationmark",
                        color: .blue
                    )
                    
                    KPICard(
                        title: "CRITICAL ALERTS",
                        value: "\(store.workOrders.filter { $0.priority == .critical }.count)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                    
                    KPICard(
                        title: "LOW STOCK",
                        value: "\(store.lowStockCount)",
                        icon: "shippingbox.fill",
                        color: .orange
                    )
                    
                    KPICard(
                        title: "COMPLIANCE",
                        value: "\(Int(store.complianceScore))%",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Recent Activity / Shortcuts
                VStack(alignment: .leading, spacing: 16) {
                    Text("RECENT WORK ORDERS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(store.workOrders.prefix(3)) { order in
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(order.priority == .critical ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: order.priority == .critical ? "bolt.fill" : "wrench.and.screwdriver.fill")
                                            .foregroundColor(order.priority == .critical ? .red : .blue)
                                            .font(.system(size: 14))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.title)
                                        .font(.system(size: 15, weight: .bold))
                                    Text(order.vehicleName)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            
                            if order.id != store.workOrders.prefix(3).last?.id {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
