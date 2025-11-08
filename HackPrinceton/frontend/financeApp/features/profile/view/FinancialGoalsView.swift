//
//  FinancialGoalsView.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI

struct FinancialGoalsView: View {
    @StateObject private var vm = FinancialGoalsViewModel()
    @State private var showingAddGoal = false
    @State private var selectedGoal: FinancialGoalItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress Card
                    if !vm.activeGoals.isEmpty {
                        OverallProgressCard(vm: vm)
                    }
                    
                    // Active Goals Section
                    if !vm.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Goals")
                                .font(.headline)
                                .padding(.horizontal, DS.pad)
                            
                            ForEach(vm.activeGoals) { goal in
                                GoalCard(goal: goal) {
                                    selectedGoal = goal
                                }
                                .padding(.horizontal, DS.pad)
                            }
                        }
                    }
                    
                    // Completed Goals Section
                    if !vm.completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completed Goals")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DS.pad)
                            
                            ForEach(vm.completedGoals) { goal in
                                GoalCard(goal: goal) {
                                    selectedGoal = goal
                                }
                                .padding(.horizontal, DS.pad)
                                .opacity(0.7)
                            }
                        }
                    }
                    
                    // Empty State
                    if vm.goals.isEmpty {
                        EmptyGoalsState {
                            showingAddGoal = true
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Financial Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DS.cardGradientStart)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddEditGoalView(vm: vm)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(vm: vm, goal: goal)
            }
        }
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    @ObservedObject var vm: FinancialGoalsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(currencyString(vm.totalCurrentAmount))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.cardGradientStart)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(vm.totalTargetAmount))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
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
                        .frame(width: geometry.size.width * vm.overallProgress)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(Int(vm.overallProgress * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.cardGradientStart)
                
                Spacer()
                
                Text("\(currencyString(vm.totalRemainingAmount)) to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, DS.pad)
    }
    
    private func currencyString(_ decimal: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        let num = NSDecimalNumber(decimal: decimal)
        return formatter.string(from: num) ?? "$0.00"
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: FinancialGoalItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Category Icon
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: goal.category.icon)
                            .foregroundStyle(categoryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(goal.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Progress Section
                if !goal.isCompleted {
                    VStack(spacing: 8) {
                        HStack {
                            Text(currencyString(goal.currentAmount))
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("of \(currencyString(goal.targetAmount))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(categoryColor)
                                    .frame(width: geometry.size.width * goal.progress)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("\(goal.progressPercentage)% Complete")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(categoryColor)
                            
                            Spacer()
                            
                            if let days = goal.daysRemaining {
                                if days > 0 {
                                    Text("\(days) days left")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if days == 0 {
                                    Text("Due today")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("Overdue")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Text(currencyString(goal.currentAmount))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        
                        Spacer()
                        
                        Text("Completed!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(DS.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.outline))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        switch goal.category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "pink": return .pink
        case "teal": return .teal
        default: return .gray
        }
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

// MARK: - Empty State

struct EmptyGoalsState: View {
    let onAddGoal: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🎯")
                .font(.system(size: 80))
            
            Text("No Goals Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Set financial goals and track your progress towards achieving them")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Button {
                onAddGoal()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Goal")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [DS.cardGradientStart, DS.cardGradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    FinancialGoalsView()
}
