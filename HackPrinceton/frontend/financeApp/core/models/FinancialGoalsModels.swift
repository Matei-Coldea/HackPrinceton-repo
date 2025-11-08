//
//  FinancialGoalsModels.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation

struct FinancialGoalItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var deadline: Date?
    var category: GoalCategory
    var notes: String?
    var createdDate: Date
    var isCompleted: Bool
    
    var progress: Double {
        let target = NSDecimalNumber(decimal: targetAmount).doubleValue
        let current = NSDecimalNumber(decimal: currentAmount).doubleValue
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }
    
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
        return days
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case emergency = "Emergency Fund"
    case travel = "Travel"
    case home = "Home Purchase"
    case car = "Car"
    case debt = "Pay Off Debt"
    case retirement = "Retirement"
    case education = "Education"
    case wedding = "Wedding"
    case general = "General Savings"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .emergency: return "shield.fill"
        case .travel: return "airplane"
        case .home: return "house.fill"
        case .car: return "car.fill"
        case .debt: return "creditcard.fill"
        case .retirement: return "chart.line.uptrend.xyaxis"
        case .education: return "graduationcap.fill"
        case .wedding: return "heart.fill"
        case .general: return "banknote.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .emergency: return "blue"
        case .travel: return "purple"
        case .home: return "green"
        case .car: return "red"
        case .debt: return "orange"
        case .retirement: return "indigo"
        case .education: return "cyan"
        case .wedding: return "pink"
        case .general: return "teal"
        case .other: return "gray"
        }
    }
}
