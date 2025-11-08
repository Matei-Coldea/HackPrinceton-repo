//
//  FinanceCardView.swift
//
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

struct FinanceCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Balance")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("$5,432.89")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("$3,240")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1, height: 40)
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("$1,827")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [DS.cardGradientStart, DS.cardGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.radius))
        .shadow(color: DS.cardGradientStart.opacity(0.4), radius: 20, y: 10)
        .padding(.horizontal, DS.pad)
    }
}

#Preview {
    FinanceCardView()
}
