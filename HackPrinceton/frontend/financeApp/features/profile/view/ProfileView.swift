//
//  ProfileView.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderCard(vm: vm, showingEditProfile: $showingEditProfile)
                    
                    // Lifetime Stats
                    LifetimeStatsCard(vm: vm)
                    
                    // Financial Goals Section
                    FinancialGoalsSection()
                    
                    // Achievements
                    AchievementsCard(vm: vm)
                    
                    // Account Info
                    AccountInfoSection(vm: vm)
                    
                    // Settings & Actions
                    SettingsSection(showingSettings: $showingSettings)
                    
                    // App Info
                    AppInfoSection()
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(vm: vm)
            }
        }
        .task {
            vm.load()
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    @ObservedObject var vm: ProfileViewModel
    @Binding var showingEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Photo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.cardGradientStart, DS.cardGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(vm.initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 4) {
                Text(vm.userName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(vm.memberSince)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Quick Stats Row
            HStack(spacing: 32) {
                QuickStatItem(
                    value: "\(vm.currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )
                
                QuickStatItem(
                    value: "Level \(vm.level)",
                    label: "Current Level",
                    icon: "star.fill",
                    color: DS.cardGradientStart
                )
                
                QuickStatItem(
                    value: "\(vm.achievementsUnlocked)",
                    label: "Achievements",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            .padding(.top, 8)
            
            // Edit Profile Button
            Button {
                showingEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.cardGradientStart)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.cardGradientStart.opacity(0.1))
                    )
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Lifetime Stats Card

struct LifetimeStatsCard: View {
    @ObservedObject var vm: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lifetime Stats")
                .font(.headline)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                StatRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    title: "Total Saved",
                    value: vm.totalSaved,
                    trend: "+$127 this month"
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                StatRow(
                    icon: "calendar.circle.fill",
                    iconColor: .blue,
                    title: "Days Active",
                    value: "\(vm.daysActive) days",
                    trend: "Since \(vm.joinDate)"
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                StatRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .purple,
                    title: "Impulses Resisted",
                    value: "\(vm.impulsesResisted)",
                    trend: "\(vm.successRate)% success rate"
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                StatRow(
                    icon: "location.circle.fill",
                    iconColor: .orange,
                    title: "Trigger Locations Avoided",
                    value: "\(vm.locationsAvoided)",
                    trend: "Top: Target, Starbucks"
                )
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Text(trend)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Financial Goals Section

struct FinancialGoalsSection: View {
    @StateObject private var goalsVM = FinancialGoalsViewModel()
    
    var body: some View {
        NavigationLink {
            FinancialGoalsView()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Financial Goals")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(goalsVM.activeGoals.count) active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                if goalsVM.activeGoals.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Text("🎯")
                            .font(.system(size: 48))
                        
                        Text("Set your first financial goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Tap to get started")
                            .font(.caption)
                            .foregroundStyle(DS.cardGradientStart)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    // Show quick summary
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Progress")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(currencyString(goalsVM.totalCurrentAmount))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(DS.cardGradientStart)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Target")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(currencyString(goalsVM.totalTargetAmount))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [DS.cardGradientStart, DS.cardGradientEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * goalsVM.overallProgress)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("\(Int(goalsVM.overallProgress * 100))% Complete")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.cardGradientStart)
                            
                            Spacer()
                            
                            Text("View all goals")
                                .font(.caption)
                                .foregroundStyle(DS.cardGradientStart)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            .padding(.horizontal, DS.pad)
        }
        .buttonStyle(.plain)
    }
    
    private func currencyString(_ decimal: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        let num = NSDecimalNumber(decimal: decimal)
        return formatter.string(from: num) ?? "$0"
    }
}

// MARK: - Achievements Card

struct AchievementsCard: View {
    @ObservedObject var vm: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    // TODO: Show all achievements
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(DS.cardGradientStart)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.recentAchievements) { achievement in
                        AchievementBadgeCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct AchievementBadgeCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? DS.cardGradientStart.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(achievement.emoji)
                    .font(.title)
                    .opacity(achievement.unlocked ? 1 : 0.3)
            }
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - Account Info Section

struct AccountInfoSection: View {
    @ObservedObject var vm: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Information")
                .font(.headline)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                InfoRow(icon: "envelope.fill", label: "Email", value: vm.email)
                Divider().padding(.leading, 52)
                InfoRow(icon: "phone.fill", label: "Phone", value: vm.phone)
                Divider().padding(.leading, 52)
                InfoRow(icon: "creditcard.fill", label: "Linked Accounts", value: "\(vm.linkedAccounts) accounts")
            }
        }
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DS.cardGradientStart)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "bell.fill", title: "Notifications", iconColor: .orange) {
                // TODO: Navigate to notifications settings
            }
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "lock.fill", title: "Privacy & Security", iconColor: .blue) {
                // TODO: Navigate to privacy settings
            }
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "link", title: "Connected Services", iconColor: .green) {
                // TODO: Navigate to connected services
            }
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", iconColor: .purple) {
                // TODO: Navigate to help
            }
        }
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Info Section

struct AppInfoSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Guardian v1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Button("Terms of Service") {
                    // TODO: Show terms
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Button {
                // TODO: Sign out
            } label: {
                Text("Sign Out")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Placeholder Views (for sheets)

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Toggle("Location Alerts", isOn: .constant(true))
                    Toggle("Success Celebrations", isOn: .constant(true))
                    Toggle("Weekly Reports", isOn: .constant(true))
                }
                
                Section("Privacy") {
                    Toggle("Share Anonymous Data", isOn: .constant(false))
                    Button("Delete Account") {
                        // TODO: Delete account flow
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: ProfileViewModel
    @State private var editedName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $editedName)
                }
                
                Section("Photo") {
                    Button("Change Profile Photo") {
                        // TODO: Photo picker
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.updateName(editedName)
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedName = vm.userName
            }
        }
    }
}

#Preview {
    ProfileView()
}
