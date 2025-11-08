//
//  OnboardingView.swift
//
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI
import Combine

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [DS.cardGradientStart.opacity(0.1), DS.cardGradientEnd.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $vm.currentStep) {
                WelcomeScreen(onContinue: { vm.nextStep() })
                    .tag(0)
                
                SpendingCategoriesScreen(
                    selectedCategories: $vm.data.spendingCategories,
                    onContinue: { vm.nextStep() },
                    onSkip: { vm.nextStep() }
                )
                .tag(1)
                
                FinancialGoalsScreen(
                    selectedGoals: $vm.data.financialGoals,
                    onContinue: { vm.nextStep() },
                    onSkip: { vm.nextStep() }
                )
                .tag(2)
                
                LinkKnotScreen(
                    isLinked: $vm.data.linkedKnot,
                    onContinue: { vm.nextStep() },
                    onSkip: { vm.nextStep() }
                )
                .tag(3)
                
                LinkPlaidScreen(
                    isLinked: $vm.data.linkedPlaid,
                    onContinue: { vm.nextStep() },
                    onSkip: { vm.nextStep() }
                )
                .tag(4)
                
                LinkCalendarScreen(
                    isLinked: $vm.data.linkedCalendar,
                    onFinish: { vm.completeOnboarding(completion: { isOnboardingComplete = true }) }
                )
                .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            
            // Progress indicator
            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<6) { index in
                        Capsule()
                            .fill(index <= vm.currentStep ? DS.cardGradientStart : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)
                
                Spacer()
            }
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var data = OnboardingData()
    
    func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    func completeOnboarding(completion: @escaping () -> Void) {
        // TODO: Backend will save onboarding data
        // Save to UserDefaults that onboarding is complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Log what user selected
        print("📊 Onboarding Complete!")
        print("Spending categories: \(data.spendingCategories.map { $0.rawValue })")
        print("Financial goals: \(data.financialGoals.map { $0.rawValue })")
        print("Knot linked: \(data.linkedKnot)")
        print("Plaid linked: \(data.linkedPlaid)")
        print("Calendar linked: \(data.linkedCalendar)")
        
        completion()
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
