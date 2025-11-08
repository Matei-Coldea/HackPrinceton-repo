//
//  FinancialGoalsViewModel.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation

@MainActor
final class FinancialGoalsViewModel: ObservableObject {
    @Published var goals: [FinancialGoalItem] = []
    @Published var isLoading = false
    
    init() {
        loadGoals()
    }
    
    func loadGoals() {
        // TODO: Backend will load from API/database
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Mock data
            goals = [
                FinancialGoalItem(
                    title: "Emergency Fund",
                    targetAmount: 10000,
                    currentAmount: 3500,
                    deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                    category: .emergency,
                    notes: "6 months of expenses",
                    createdDate: Date().addingTimeInterval(-86400 * 90),
                    isCompleted: false
                ),
                FinancialGoalItem(
                    title: "Europe Trip",
                    targetAmount: 5000,
                    currentAmount: 4200,
                    deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                    category: .travel,
                    notes: "Summer vacation to Italy and Greece",
                    createdDate: Date().addingTimeInterval(-86400 * 120),
                    isCompleted: false
                ),
                FinancialGoalItem(
                    title: "New Laptop",
                    targetAmount: 2000,
                    currentAmount: 2000,
                    deadline: nil,
                    category: .general,
                    notes: "MacBook Pro for work",
                    createdDate: Date().addingTimeInterval(-86400 * 60),
                    isCompleted: true
                ),
                FinancialGoalItem(
                    title: "Pay Off Credit Card",
                    targetAmount: 3500,
                    currentAmount: 1200,
                    deadline: Calendar.current.date(byAdding: .month, value: 8, to: Date()),
                    category: .debt,
                    notes: "High interest credit card",
                    createdDate: Date().addingTimeInterval(-86400 * 45),
                    isCompleted: false
                )
            ]
            
            isLoading = false
        }
    }
    
    func addGoal(_ goal: FinancialGoalItem) {
        goals.insert(goal, at: 0)
        saveGoals()
        print("✅ Goal added: \(goal.title)")
    }
    
    func updateGoal(_ goal: FinancialGoalItem) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
            print("✅ Goal updated: \(goal.title)")
        }
    }
    
    func deleteGoal(_ goal: FinancialGoalItem) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
        print("🗑️ Goal deleted: \(goal.title)")
    }
    
    func updateGoalProgress(_ goalId: UUID, newAmount: Decimal) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].currentAmount = newAmount
            
            // Auto-complete if target reached
            if newAmount >= goals[index].targetAmount {
                goals[index].isCompleted = true
                print("🎉 Goal completed: \(goals[index].title)")
            }
            
            saveGoals()
        }
    }
    
    func toggleComplete(_ goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].isCompleted.toggle()
            saveGoals()
        }
    }
    
    private func saveGoals() {
        // TODO: Backend will save to API/database
        // For now, could save to UserDefaults
        print("💾 Saving goals...")
    }
    
    var activeGoals: [FinancialGoalItem] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [FinancialGoalItem] {
        goals.filter { $0.isCompleted }
    }
    
    var totalTargetAmount: Decimal {
        activeGoals.reduce(0) { $0 + $1.targetAmount }
    }
    
    var totalCurrentAmount: Decimal {
        activeGoals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var totalRemainingAmount: Decimal {
        activeGoals.reduce(0) { $0 + $1.remainingAmount }
    }
    
    var overallProgress: Double {
        let total = NSDecimalNumber(decimal: totalTargetAmount).doubleValue
        let current = NSDecimalNumber(decimal: totalCurrentAmount).doubleValue
        guard total > 0 else { return 0 }
        return min(current / total, 1.0)
    }
}
