//
//  financeCardView.swift
//
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

struct FinanceCardView: View {
    var body: some View {
        let cardWidth = UIScreen.main.bounds.width - 32
        let cardHeight = cardWidth / 1.586
        
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [DS.cardGradientStart, DS.cardGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 0) {
                // Top section - Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Balance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text("$5,432.89")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 16)
                .padding(.leading, 20)
                
                Spacer()
                
                // Bottom section - Income & Expenses
                HStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("INCOME")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .tracking(0.5)
                        Text("$3,240")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXPENSES")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .tracking(0.5)
                        Text("$1,827")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 16)
            }
            
            // Decorative chip (like on credit cards)
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(width: 40, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )
                .position(x: cardWidth - 50, y: 30)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: DS.cardGradientStart.opacity(0.3), radius: 15, y: 8)
        .padding(.horizontal, DS.pad)
    }
}

#Preview {
    FinanceCardView()
}
