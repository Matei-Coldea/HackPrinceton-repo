//
//  app.swift
//
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

@main
struct FinanceAppApp: App {
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
                    .onAppear {
                        // Request notification permissions
                        Task {
                            let granted = await NotificationManager.shared.requestPermission()
                            if granted {
                                print("✅ Notifications enabled")
                            } else {
                                print("❌ Notifications denied")
                            }
                        }
                    }
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
            }
        }
    }
}
