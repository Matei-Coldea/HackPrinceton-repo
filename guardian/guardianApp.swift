//
//  guardianApp.swift
//  guardian
//
//  Created by Islom Shamsiev on 2025/11/8.
//

import SwiftUI

@main
struct guardianApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @State private var showGetInView = false
    
    var body: some View {
        ZStack {
            if showGetInView {
                GetInView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showGetInView)
        .onAppear {
            // Show ContentView for 2.5 seconds, then fade to GetInView
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showGetInView = true
                }
            }
        }
    }
}
