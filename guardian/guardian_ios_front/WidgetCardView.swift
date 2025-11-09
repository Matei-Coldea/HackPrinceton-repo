//
//  WidgetCardView.swift
//
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI
import Combine

struct WidgetCardView: View {
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Main Balance Card
            FinanceCardContainer(amountMoney: 10000, income: 1000, expenses: 200)
                .tag(0)
            
            // Page 2: Secondary Card
            FinanceCardContainer(amountMoney: 5000, income: 800, expenses: 300)
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .frame(height: 240)
    }
}


#Preview {
    WidgetCardView()
}
