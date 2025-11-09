import SwiftUI
import UserNotifications

struct HomeView: View {
    @State private var showingNotifications = false
    @State private var showTestAlert = false
    @State private var showingAnalytics = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Custom "navigation bar"
                    HStack {
    
                            Text("Guardian")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                      

                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                showingAnalytics = true
                            } label: {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                showingNotifications = true
                            } label: {
                                Image("bot")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    
                    // --- Rest of your UI ---
                    Text("Your GuardWallet")
                        .fontWeight(.semibold)
                        .font(.system(size: 20, design: .rounded))
                        .hAlign(.leading)
                        .padding(.leading, 25)
                        .padding(.bottom, 8)
                    
                    WidgetCardView()
                        .frame(height: 230)
                    
                    Text("Today's Data")
                        .fontWeight(.semibold)
                        .font(.system(size: 35, design: .serif))
                        .hAlign(.leading)
                        .padding(.leading, 25)
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsTableView()
            }
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    // MARK: - Local Notification Prototype
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            }
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "MindfulSpend Alert"
        content.body = "This is a prototype notification from tapping Guardian!"
        content.sound = .default
        
        // Trigger 3 seconds later
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}

#Preview {
    HomeView()
}
