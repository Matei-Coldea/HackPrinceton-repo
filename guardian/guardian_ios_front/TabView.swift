import SwiftUI


enum CustomTab: String, CaseIterable {
    case home = "Home"
    case notifications = "Analytics"
    case settings = "Profile"
    
    var symbol: String{
        switch self{
        case .home: return "wallet.bifold.fill"
        case .notifications: return "chart.bar.xaxis"
        case .settings: return "person.crop.circle.fill"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}


struct Tabb: View {
    @State private var activeTab: CustomTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab){
                HomeView()
                    .tag(CustomTab.home)
                
                AnalyticsTableView()
                    .tag(CustomTab.notifications)
                
                ProfileView()
                    .tag(CustomTab.settings)
            }
            .tabViewStyle(.automatic)
            .toolbar(.hidden, for: .tabBar)
            
            CustomTabBarView()
                .padding(.horizontal, 20)
                .padding(.bottom, 0)
                .background(
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .onAppear {
            // Send notification when app opens
            LocationNotificationService.shared.sendTestNotification()
        }
    }
    @ViewBuilder
    func CustomTabBarView() -> some View {
        HStack(spacing: 10){
            GeometryReader{
                CustomTabBar(size: $0.size, activeTab: $activeTab){tab in
                    VStack(spacing: 3){
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .symbolVariant(.fill)
                    .frame(maxWidth: .infinity)
                }
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 25, style: .continuous)
                )
            }
        }
        .frame(height: 55)
    }
}

// Blur fade in/out

extension View {
    @ViewBuilder
    func blurFade(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }
}

#Preview {
    Tabb()
}

