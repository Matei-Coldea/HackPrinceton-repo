//
//  ProfileViewModel.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let unlocked: Bool
    let unlockedDate: Date?
}

// MARK: - Profile View Model

@MainActor
final class ProfileViewModel: ObservableObject {
    // User Info
    @Published var userName = "Alex Johnson"
    @Published var email = "alex.johnson@email.com"
    @Published var phone = "+1 (555) 123-4567"
    @Published var memberSince = "Member since June 2025"
    @Published var joinDate = "June 2025"
    
    // Stats
    @Published var currentStreak = 7
    @Published var level = 3
    @Published var achievementsUnlocked = 8
    @Published var totalSaved = "$880.00"
    @Published var daysActive = 156
    @Published var impulsesResisted = 47
    @Published var successRate = 78
    @Published var locationsAvoided = 23
    @Published var linkedAccounts = 3
    
    // Achievements
    @Published var recentAchievements: [Achievement] = []
    @Published var allAchievements: [Achievement] = []
    
    @Published var isLoading = true
    
    func load() {
        // TODO: Backend will load real user data
        isLoading = true
        
        // Simulate loading delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Load achievements
            loadAchievements()
            
            isLoading = false
        }
    }
    
    func updateName(_ newName: String) {
        userName = newName
        // TODO: Backend will save the updated name
        print("📝 Name updated to: \(newName)")
    }
    
    var initials: String {
        let names = userName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        } else if let first = names.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    private func loadAchievements() {
        // Mock achievements - backend will load real data
        allAchievements = [
            Achievement(
                emoji: "🎉",
                title: "First Save",
                description: "Saved your first dollar",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 150)
            ),
            Achievement(
                emoji: "💪",
                title: "Resisted 5x",
                description: "Resisted 5 impulse purchases",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 120)
            ),
            Achievement(
                emoji: "🔥",
                title: "7-Day Streak",
                description: "Maintained a 7-day streak",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 7)
            ),
            Achievement(
                emoji: "💰",
                title: "$500 Saved",
                description: "Saved $500 total",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 60)
            ),
            Achievement(
                emoji: "🎯",
                title: "Target Avoided",
                description: "Avoided your trigger location 10 times",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 45)
            ),
            Achievement(
                emoji: "🏆",
                title: "Level 3",
                description: "Reached Level 3",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 30)
            ),
            Achievement(
                emoji: "⭐",
                title: "Perfect Week",
                description: "Completed a week with 100% success",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 14)
            ),
            Achievement(
                emoji: "🌟",
                title: "Early Bird",
                description: "Avoided late-night spending 10 times",
                unlocked: true,
                unlockedDate: Date().addingTimeInterval(-86400 * 20)
            ),
            Achievement(
                emoji: "🎖️",
                title: "30-Day Warrior",
                description: "Maintained a 30-day streak",
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                emoji: "💎",
                title: "$1000 Saved",
                description: "Saved $1000 total",
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                emoji: "👑",
                title: "Guardian Master",
                description: "Reached Level 10",
                unlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                emoji: "🚀",
                title: "100 Impulses",
                description: "Resisted 100 impulse purchases",
                unlocked: false,
                unlockedDate: nil
            )
        ]
        
        // Show recently unlocked achievements
        recentAchievements = allAchievements
            .filter { $0.unlocked }
            .sorted { ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast) }
            .prefix(6)
            .map { $0 }
    }
}
