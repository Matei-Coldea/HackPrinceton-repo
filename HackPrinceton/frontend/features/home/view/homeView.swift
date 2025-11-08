//
//  homeView.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

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
                ToolbarItem(placement: .topBarLeading) { Image(systemName: "line.3.horizontal") }
                ToolbarItem(placement: .topBarTrailing) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                        Circle().fill(.red).frame(width: 8, height: 8).offset(x: 6, y: -4)
                    }
                }
            }
            .task { vm.load() }
        }
    }
}

#Preview {
    HomeView()
}
