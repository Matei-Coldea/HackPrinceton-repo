//
//  OnboardingModels.swift
//  
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation

struct OnboardingData {
    var spendingCategories: Set<SpendingCategory> = []
    var financialGoals: Set<FinancialGoal> = []
    var linkedKnot: Bool = false
    var linkedPlaid: Bool = false
    var linkedCalendar: Bool = false
}

enum SpendingCategory: String, CaseIterable, Identifiable {
    case foodDelivery = "Food Delivery"
    case coffee = "Coffee & Cafes"
    case shopping = "Online Shopping"
    case subscriptions = "Subscriptions"
    case dining = "Dining Out"
    case entertainment = "Entertainment"
    case impulse = "Impulse Purchases"
    case rideshare = "Rideshare & Transit"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .foodDelivery: return "🍕"
        case .coffee: return "☕️"
        case .shopping: return "🛍️"
        case .subscriptions: return "📱"
        case .dining: return "🍽️"
        case .entertainment: return "🎬"
        case .impulse: return "💸"
        case .rideshare: return "🚗"
        }
    }
}

enum FinancialGoal: String, CaseIterable, Identifiable {
    case buildEmergencyFund = "Build emergency fund"
    case payOffDebt = "Pay off debt"
    case saveForTravel = "Save for travel"
    case buyHome = "Buy a home"
    case retirement = "Save for retirement"
    case stopImpulseBuying = "Stop impulse buying"
    case reduceSubscriptions = "Cut subscriptions"
    case saveForEducation = "Save for education"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .buildEmergencyFund: return "🏦"
        case .payOffDebt: return "💳"
        case .saveForTravel: return "✈️"
        case .buyHome: return "🏠"
        case .retirement: return "👴"
        case .stopImpulseBuying: return "🛑"
        case .reduceSubscriptions: return "📉"
        case .saveForEducation: return "🎓"
        }
    }
}
