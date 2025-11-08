//
//  savingsChartView.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI
import Charts   // Add Apple Charts (iOS 16+)

struct SavingsChartView: View {
    let cumulative: [(Date, Decimal)]

    var body: some View {
        Chart {
            ForEach(Array(cumulative.enumerated()), id: \.offset) { _, p in
                let y = NSDecimalNumber(decimal: p.1).doubleValue
                AreaMark(x: .value("Month", p.0), y: .value("Saved", y))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.25)
                LineMark(x: .value("Month", p.0), y: .value("Saved", y))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 3, lineCap: .round))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) {
                AxisGridLine(); AxisTick(); AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .padding(.top, 4)
    }
}

