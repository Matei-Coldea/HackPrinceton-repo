//
//  WidgetCardView.swift
//
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI
import Combine

struct WidgetCardView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Savings Chart
            SavingsWidgetPage(vm: vm)
                .tag(0)
            
            // Page 2: Gamification (placeholder for now)
            GamificationWidgetPage()
                .tag(1)
            
            // Page 3: Another widget (placeholder)
            PlaceholderWidgetPage(
                icon: "🎯",
                title: "Goals",
                subtitle: "Track your progress"
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .frame(height: 320)
        .task {
            vm.load()
        }
    }
}

struct SavingsWidgetPage: View {
    @ObservedObject var vm: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(currencyString(vm.totalSaved))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.positive)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(DS.positive)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Total Savings")
                    .font(.headline)
                Text(sinceText(vm.sinceDate))
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom, 4)

            SavingsChartView(cumulative: vm.cumulative)
                .frame(height: 170)
                .padding(.top, 8)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
    
    private func sinceText(_ date: Date?) -> String {
        guard let d = date else { return "Since you started" }
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return "Since \(f.string(from: d))"
    }
    
    private func currencyString(_ dec: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        let num = NSDecimalNumber(decimal: dec)
        return formatter.string(from: num) ?? "$0.00"
    }
}

struct GamificationWidgetPage: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 7 Day Streak")
                        .font(.headline)
                    Text("Keep it up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Level 3")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.cardGradientStart)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Progress to Level 4")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("65%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [DS.cardGradientStart, DS.cardGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.65)
                    }
                }
                .frame(height: 12)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                AchievementBadge(emoji: "🏆", title: "First Save", unlocked: true)
                AchievementBadge(emoji: "💪", title: "Resisted 5x", unlocked: true)
                AchievementBadge(emoji: "🎯", title: "Goal Met", unlocked: false)
            }
            
            Spacer()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct AchievementBadge: View {
    let emoji: String
    let title: String
    let unlocked: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title)
                .opacity(unlocked ? 1 : 0.3)
            Text(title)
                .font(.caption2)
                .foregroundStyle(unlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(unlocked ? DS.cardGradientStart.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

struct PlaceholderWidgetPage: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(icon)
                .font(.system(size: 60))
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

#Preview {
    WidgetCardView()
}
