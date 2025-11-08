//
//  OnboardingScreens.swift
//  
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("💸")
                .font(.system(size: 80))
            
            Text("Stop spending.\nStart saving.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("We use psychology and ML to stop you from impulse buying at your most vulnerable moments")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                onContinue()
            } label: {
                Text("Let's go")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [DS.cardGradientStart, DS.cardGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Spending Categories Screen

struct SpendingCategoriesScreen: View {
    @Binding var selectedCategories: Set<SpendingCategory>
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Where does your money go?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 100)
            .padding(.horizontal, 32)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SpendingCategory.allCases) { category in
                        CategoryButton(
                            emoji: category.icon,
                            title: category.rawValue,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedCategories.isEmpty ? Color.gray : DS.cardGradientStart)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedCategories.isEmpty)
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Financial Goals Screen

struct FinancialGoalsScreen: View {
    @Binding var selectedGoals: Set<FinancialGoal>
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What are your goals?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 100)
            .padding(.horizontal, 32)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(FinancialGoal.allCases) { goal in
                        CategoryButton(
                            emoji: goal.icon,
                            title: goal.rawValue,
                            isSelected: selectedGoals.contains(goal)
                        ) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedGoals.isEmpty ? Color.gray : DS.cardGradientStart)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedGoals.isEmpty)
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Link Knot Screen

struct LinkKnotScreen: View {
    @Binding var isLinked: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        IntegrationScreen(
            icon: "🔗",
            title: "Connect Knot",
            description: "Link your Knot account to get better analytics on specific purchases and transactions",
            buttonTitle: "Connect Knot",
            isLinked: $isLinked,
            onContinue: onContinue,
            onSkip: onSkip
        )
    }
}

// MARK: - Link Plaid Screen

struct LinkPlaidScreen: View {
    @Binding var isLinked: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        IntegrationScreen(
            icon: "🏦",
            title: "Connect Your Bank",
            description: "Securely link your bank account with Plaid to track spending patterns and predict vulnerable moments",
            buttonTitle: "Connect Bank",
            isLinked: $isLinked,
            onContinue: onContinue,
            onSkip: onSkip
        )
    }
}

// MARK: - Link Calendar Screen

struct LinkCalendarScreen: View {
    @Binding var isLinked: Bool
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("📅")
                .font(.system(size: 80))
            
            Text("Sync Calendar")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("Link your calendar so we can help you save for upcoming events like birthdays, holidays, and trips")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    // TODO: Backend implements calendar linking
                    isLinked = true
                    print("📅 Calendar linking initiated")
                    onFinish()
                } label: {
                    HStack {
                        Image(systemName: isLinked ? "checkmark.circle.fill" : "calendar")
                        Text(isLinked ? "Calendar Connected" : "Connect Calendar")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isLinked ? Color.green : DS.cardGradientStart)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    onFinish()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Reusable Components

struct CategoryButton: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.cardGradientStart)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? DS.cardGradientStart.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? DS.cardGradientStart : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct IntegrationScreen: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    @Binding var isLinked: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(icon)
                .font(.system(size: 80))
            
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    // TODO: Backend implements linking
                    isLinked = true
                    print("🔗 \(title) linking initiated")
                    onContinue()
                } label: {
                    HStack {
                        Image(systemName: isLinked ? "checkmark.circle.fill" : "link")
                        Text(isLinked ? "Connected" : buttonTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isLinked ? Color.green : DS.cardGradientStart)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview("Welcome") {
    WelcomeScreen(onContinue: {})
}

#Preview("Spending") {
    SpendingCategoriesScreen(
        selectedCategories: .constant([]),
        onContinue: {},
        onSkip: {}
    )
}

#Preview("Goals") {
    FinancialGoalsScreen(
        selectedGoals: .constant([]),
        onContinue: {},
        onSkip: {}
    )
}
