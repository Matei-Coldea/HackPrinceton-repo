//
//  app.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import SwiftUI

@main
struct FinanceAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    // Request notification permissions when app appears
                    Task {
                        let granted = await NotificationManager.shared.requestPermission()
                        if granted {
                            print("✅ Notifications enabled")
                        } else {
                            print("❌ Notifications denied")
                        }
                    }
                }
        }
    }
}

