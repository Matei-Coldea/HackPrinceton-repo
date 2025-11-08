//
//  financeCardView.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

struct SavingsCardView<Chart: View>: View {
    let total: Decimal
    let sinceDate: Date?
    @ViewBuilder var chart: () -> Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(currencyString(total))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.positive)
                Image(systemName: "arrow.up.right").foregroundStyle(DS.positive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Savings").font(.headline)
                Text(sinceText).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            chart().clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }

    private var sinceText: String {
        guard let d = sinceDate else { return "Since you started" }
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"
        return "Since \(f.string(from: d))"
    }

    private func currencyString(_ d: Decimal) -> String {
        let v = NSDecimalNumber(decimal: d).doubleValue
        return (v as NSNumber).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
