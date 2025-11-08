//
//  homeView.swift
//
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showingNotifications = false
    @State private var showTestAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FinanceCardView()

                    SavingsCardView(
                        total: vm.totalSaved,
                        sinceDate: vm.sinceDate
                    ) {
                        SavingsChartView(cumulative: vm.cumulative)
                            .frame(height: 220)
                    }

                    Button {
                        // TODO: present AI assistant later
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles.message.fill")
                            Text("Chat with AI Financial Assistant")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                    .foregroundColor(.white)
                    .shadow(radius: 4, y: 2)
                    .padding(.horizontal, DS.pad)
                    .padding(.bottom, 8)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Finance")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "line.3.horizontal")
                        .onLongPressGesture {
                            // Hidden test: long press menu icon to trigger notification
                            NotificationManager.shared.sendLocationAlert(
                                locationName: "Target",
                                averageSpend: 45,
                                riskLevel: .high,
                                distance: 150
                            )
                            showTestAlert = true
                            print("🧪 Test notification sent! Will appear in 5 seconds. Press Home (⌘⇧H) now!")
                        }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNotifications = true
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .task {
                vm.load()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .alert("Test Notification Sent! 🧪", isPresented: $showTestAlert) {
                Button("OK") { }
            } message: {
                Text("Notification will appear in 5 seconds. Press Home (⌘⇧H) NOW and wait!")
            }
        }
    }
}

#Preview {
    HomeView()
}
