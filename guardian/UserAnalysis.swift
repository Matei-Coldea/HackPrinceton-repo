//
//  UserAnalysis.swift
//  guardian
//
//  Created by Islom Shamsiev on 2025/11/8.
//

import SwiftUI

struct UserAnalysis: View {
    @State private var currentQuestionIndex = 0
    @State private var answers: [[String]] = [[], [], []]
    @State private var isConnecting = false
    @State private var showAnalysis = false
    @State private var showTab = false
    @State private var goals: [String] = []
    
    private let questions = [
        "When are you most likely to make impulse purchases?",
        "What best describes your current spending habits?",
        "What's your primary financial goal with MindfulSpend?"
    ]
    
    private let questionOptions: [[OptionItem]] = [
        [
            OptionItem(id: "late_night", text: "Late Night", icon: "moon.fill", color: .indigo, description: "After 10 PM"),
            OptionItem(id: "stress", text: "High Stress", icon: "exclamationmark.triangle.fill", color: .red, description: "During stressful times"),
            OptionItem(id: "weekend", text: "Weekends", icon: "calendar", color: .orange, description: "Friday-Sunday"),
            OptionItem(id: "specific_stores", text: "Certain Stores", icon: "storefront.fill", color: .purple, description: "Favorite retailers"),
            OptionItem(id: "social", text: "Social Events", icon: "person.2.fill", color: .blue, description: "With friends/family"),
            OptionItem(id: "online", text: "Online Shopping", icon: "cart.fill", color: .teal, description: "Browsing apps/websites")
        ],
        [
            OptionItem(id: "impulsive", text: "Impulsive Spender", icon: "bolt.fill", color: .red, description: "Buy without thinking"),
            OptionItem(id: "emotional", text: "Emotional Spender", icon: "heart.fill", color: .pink, description: "Shop when feeling down"),
            OptionItem(id: "planned", text: "Mostly Planned", icon: "checkmark.circle.fill", color: .green, description: "Think before buying"),
            OptionItem(id: "mixed", text: "Mixed Habits", icon: "arrow.triangle.2.circlepath", color: .orange, description: "Sometimes impulsive"),
            OptionItem(id: "budget_conscious", text: "Budget Conscious", icon: "dollarsign.circle.fill", color: .blue, description: "Track expenses carefully"),
            OptionItem(id: "struggling", text: "Struggling", icon: "exclamationmark.circle.fill", color: .red, description: "Hard to control spending")
        ],
        [
            OptionItem(id: "reduce_impulse", text: "Reduce Impulse Buys", icon: "hand.raised.fill", color: .orange, description: "Stop regret purchases"),
            OptionItem(id: "save_more", text: "Save More Money", icon: "banknote.fill", color: .green, description: "Build savings"),
            OptionItem(id: "awareness", text: "Spending Awareness", icon: "eye.fill", color: .blue, description: "Understand patterns"),
            OptionItem(id: "control", text: "Better Control", icon: "slider.horizontal.3", color: .purple, description: "Manage habits"),
            OptionItem(id: "goals", text: "Reach Goals", icon: "target", color: .teal, description: "Achieve financial goals"),
            OptionItem(id: "peace", text: "Peace of Mind", icon: "leaf.fill", color: .mint, description: "Less financial stress")
        ]
    ]
    
    struct OptionItem: Identifiable {
        let id: String
        let text: String
        let icon: String
        let color: Color
        let description: String
    }
    
    var body: some View {
        ZStack {
            if showTab {
                Tab()
                    .transition(.opacity)
            } else if showAnalysis {
                analysisView
                    .transition(.opacity)
            } else {
                questionView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTab)
        .animation(.easeInOut(duration: 0.3), value: showAnalysis)
        .animation(.easeInOut(duration: 0.3), value: currentQuestionIndex)
    }
    
    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress indicator
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= currentQuestionIndex ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .animation(.spring(response: 0.3), value: currentQuestionIndex)
                    }
                }
                .padding(.top, 20)
                
                Text("Question \(currentQuestionIndex + 1) of 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 30)
            
            // Question content
            VStack(alignment: .leading, spacing: 24) {
                Text(questions[currentQuestionIndex])
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Options Grid - 2 columns for 6 items
                let columns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]
                
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    ForEach(questionOptions[currentQuestionIndex]) { option in
                        OptionCard(
                            option: option,
                            isSelected: answers[currentQuestionIndex].contains(option.id)
                        ) {
                            toggleSelection(optionId: option.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            // Next button
            Button {
                if currentQuestionIndex < 2 {
                    withAnimation {
                        currentQuestionIndex += 1
                    }
                } else {
                    // Show Plaid connection screen
                    withAnimation {
                        showAnalysis = true
                    }
                }
            } label: {
                HStack {
                    Text(currentQuestionIndex < 2 ? "Next" : "Continue")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.primary)
            .disabled(answers[currentQuestionIndex].isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var analysisView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if isConnecting {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(1.5)
                    
                    Text("Making your analysis...")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 24) {
                    Text("Ready to Connect")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Connect your bank account to get personalized financial insights and recommendations.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        connectToPlaid()
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect to Plaid API")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.primary)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func toggleSelection(optionId: String) {
        if answers[currentQuestionIndex].contains(optionId) {
            answers[currentQuestionIndex].removeAll { $0 == optionId }
        } else {
            answers[currentQuestionIndex].append(optionId)
        }
    }
    
    private func connectToPlaid() {
        isConnecting = true
        
        // Simulate API connection delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showTab = true
            }
        }
    }
}

struct OptionCard: View {
    let option: UserAnalysis.OptionItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(option.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: option.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? option.color : option.color.opacity(0.7))
                }
                
                
                // Text content
                VStack(spacing: 4) {
                    Text(option.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(option.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(option.color)
                } else {
                    Spacer()
                        .frame(height: 12)
                }
            }
            
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? option.color.opacity(0.1) : Color(.systemGray6))
                
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? option.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UserAnalysis()
}
