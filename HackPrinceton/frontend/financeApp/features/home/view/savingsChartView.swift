//
//  SavingsChartView.swift
//
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI
import Charts

struct SavingsChartView: View {
    let cumulative: [(Date, Decimal)]

    var body: some View {
        Chart {
            ForEach(Array(cumulative.enumerated()), id: \.offset) { _, p in
                let y = NSDecimalNumber(decimal: p.1).doubleValue
                AreaMark(x: .value("Month", p.0), y: .value("Saved", y))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Month", p.0), y: .value("Saved", y))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 3, lineCap: .round))
                    .foregroundStyle(Color.green)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                AxisValueLabel()
                    .font(.system(size: 10))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartPlotStyle { plotArea in
            plotArea.padding(.horizontal, 4)
        }
    }
}
