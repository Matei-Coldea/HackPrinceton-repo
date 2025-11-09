//
//  ProfileView.swift
//  guardian
//
//  Created by Islom Shamsiev on 2025/11/8.
//

import SwiftUI

struct ProfileView: View {
    @State private var achievements: [Achievement] = []
    @State private var spendingStreak: Int = 0
    @State private var totalSaved: Int = 0
    @State private var purchasesPrevented: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Streak
                headerCard
                
                // Main Stats
                statsCard
                
                // Achievements
                achievementsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadProfileData()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Islombek Shamsiev")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("User since 2025")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Streak Badge
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text("\(spendingStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    Text("day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
    }
    
    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                // Total Saved - Hero Stat
                VStack(spacing: 8) {
                    Text(formatCurrency(totalSaved))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 4) {
                        Image(systemName: "banknote.fill")
                            .font(.caption)
                        Text("Total Saved")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // Prevented
                VStack(spacing: 8) {
                    Text("\(purchasesPrevented)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text("Prevented")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
    }
    
    // MARK: - Achievements Card
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if achievements.filter({ $0.isUnlocked }).isEmpty {
                Text("Complete challenges to unlock achievements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
    }
    
    // MARK: - Helper Functions
    private func loadProfileData() {
        let service = AchievementService.shared
        let (transactions, weeklyData) = AnalyticsDataService.shared.loadAllData()
        
        achievements = service.calculateAchievements(
            transactions: transactions,
            weeklyData: weeklyData
        )
        
        spendingStreak = service.calculateSpendingStreak(weeklyData: weeklyData)
        totalSaved = service.calculateTotalSaved(weeklyData: weeklyData)
        purchasesPrevented = Int.random(in: 3...12)
    }
    
    private func formatCurrency(_ amount: Int) -> String {
        if amount >= 1000 {
            let thousands = Double(amount) / 1000.0
            return String(format: "$%.1fK", thousands)
        }
        return "$\(amount)"
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        achievement.color.opacity(0.2) :
                        Color.gray.opacity(0.1)
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        achievement.isUnlocked ?
                        achievement.color :
                        Color.gray.opacity(0.5)
                    )
                
                if achievement.isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(achievement.color)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 24, height: 24)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .frame(width: 70, height: 70)
                }
            }
            
            Text(achievement.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    var isUnlocked: Bool
    let progress: Double
}

// MARK: - Achievement Service
class AchievementService {
    static let shared = AchievementService()
    
    private init() {}
    
    func calculateAchievements(transactions: [Transaction], weeklyData: [WeekData]) -> [Achievement] {
        var achievements: [Achievement] = []
        
        let firstWeekProgress = weeklyData.count >= 1 ? 1.0 : Double(weeklyData.count) / 1.0
        achievements.append(Achievement(
            title: "First Week",
            description: "Complete your first week",
            icon: "1.circle.fill",
            color: .blue,
            isUnlocked: weeklyData.count >= 1,
            progress: min(firstWeekProgress, 1.0)
        ))
        
        let streak = calculateSpendingStreak(weeklyData: weeklyData)
        let streakProgress = min(Double(streak) / 7.0, 1.0)
        achievements.append(Achievement(
            title: "Streak Master",
            description: "7 day spending streak",
            icon: "flame.fill",
            color: .orange,
            isUnlocked: streak >= 7,
            progress: streakProgress
        ))
        
        let totalSaved = calculateTotalSaved(weeklyData: weeklyData)
        let saverProgress = min(Double(totalSaved) / 1000.0, 1.0)
        achievements.append(Achievement(
            title: "Saver",
            description: "Save $1,000",
            icon: "banknote.fill",
            color: .green,
            isUnlocked: totalSaved >= 1000,
            progress: saverProgress
        ))
        
        let avgSpending = weeklyData.isEmpty ? 0 : weeklyData.reduce(0) { $0 + $1.spending } / weeklyData.count
        let mindfulProgress = avgSpending < 1500 ? 1.0 : max(0.0, 1.0 - Double(avgSpending - 1500) / 1000.0)
        achievements.append(Achievement(
            title: "Mindful",
            description: "Keep weekly spending under $1,500",
            icon: "leaf.fill",
            color: .mint,
            isUnlocked: avgSpending < 1500,
            progress: mindfulProgress
        ))
        
        let transactionCount = transactions.count
        let trackerProgress = min(Double(transactionCount) / 50.0, 1.0)
        achievements.append(Achievement(
            title: "Tracker",
            description: "Track 50 transactions",
            icon: "list.bullet.rectangle.fill",
            color: .purple,
            isUnlocked: transactionCount >= 50,
            progress: trackerProgress
        ))
        
        let weekProgress = min(Double(weeklyData.count) / 5.0, 1.0)
        achievements.append(Achievement(
            title: "Week Warrior",
            description: "Track 5 weeks",
            icon: "calendar.badge.clock",
            color: .teal,
            isUnlocked: weeklyData.count >= 5,
            progress: weekProgress
        ))
        
        return achievements
    }
    
    func calculateSpendingStreak(weeklyData: [WeekData]) -> Int {
        guard !weeklyData.isEmpty else { return 0 }
        let avgSpending = weeklyData.reduce(0) { $0 + $1.spending } / weeklyData.count
        var streak = 0
        for week in weeklyData.reversed() {
            if week.spending < avgSpending {
                streak += 1
            } else {
                break
            }
        }
        return max(1, streak)
    }
    
    func calculateTotalSaved(weeklyData: [WeekData]) -> Int {
        guard !weeklyData.isEmpty else { return 0 }
        let totalIncome = weeklyData.reduce(0) { $0 + $1.income }
        let totalSpending = weeklyData.reduce(0) { $0 + $1.spending }
        return max(0, totalIncome - totalSpending)
    }
}

#Preview {
    ProfileView()
}
