import SwiftUI

// MARK: - Main Finance Card View
struct FinanceCardView: View {
    @State var amountMoney: Int
    @State var income: Int
    @State var expenses: Int
    @State private var gradientColors: [Color] = FinanceCardView.randomGradient()
    
    var body: some View {
        let cardWidth = UIScreen.main.bounds.width - 32
        let cardHeight = cardWidth / 1.586
        
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 0) {
                // Top section - Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Balance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text("$\(amountMoney)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 16)
                .padding(.leading, 20)
                
                Spacer()
                
                // Bottom section - Income & Expenses
                HStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INCOME")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(0.5)
                            Text("$\(income)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EXPENSES")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(0.5)
                            Text("$\(expenses)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Islombek Shamsiev")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
            
            // Decorative chip
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(width: 40, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )
                .position(x: cardWidth - 50, y: 30)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradientColors.first?.opacity(0.3) ?? .black.opacity(0.3), radius: 15, y: 8)
    }
}

// MARK: - Random Gradient Generator
extension FinanceCardView {
    static func randomGradient() -> [Color] {
        let palette: [[Color]] = [
            [.purple, .pink],
            [.orange, .yellow],
            [.teal, .blue],
            [.indigo, .cyan],
            [Color(red: 0.22, green: 0.69, blue: 0.0), .green],
            [.red, .orange],
            [.mint, .teal]
        ]
        return palette.randomElement() ?? [.blue, .green]
    }
}

// MARK: - Card Container with Floating Feature
struct FinanceCardContainer: View {
    @State var amountMoney: Int
    @State var income: Int
    @State var expenses: Int
    @State private var showFloatingView = false
    
    private let sidePadding: CGFloat = 16
    private let maxCardWidth: CGFloat = 360
    
    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width - (sidePadding * 2), maxCardWidth)
    }
    private var cardHeight: CGFloat { cardWidth / 1.586 }
    
    var body: some View {
        FinanceCardView(amountMoney: amountMoney, income: income, expenses: expenses)
            .frame(width: cardWidth, height: cardHeight)
            .onTapGesture { showFloatingView = true }
            .fullScreenCover(isPresented: $showFloatingView) {
                FloatingCardScreen(
                    amountMoney: amountMoney,
                    income: income,
                    expenses: expenses
                ) {
                    showFloatingView = false
                }
            }
    }
}

// MARK: - Floating Card Screen
struct FloatingCardScreen: View {
    enum FlowState { case idle, checking, risky, approved, cancelled }
    
    var amountMoney: Int
    var income: Int
    var expenses: Int
    var onDone: () -> Void
    
    @State private var state: FlowState = .idle
    @State private var isFlipped = false
    @State private var showSuccess = false
    
    private let useBlurScrim = true
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }
    private var cardHeight: CGFloat { cardWidth / 1.586 }
    
    var body: some View {
        GeometryReader { proxy in
            let topSafe = proxy.safeAreaInsets.top
            
            ZStack(alignment: .top) {
                // Clean background
                if useBlurScrim {
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                } else {
                    Color.black.opacity(0.35).ignoresSafeArea()
                }
                
                // Card at the top
                ZStack {
                    // FRONT
                    FinanceCardView(
                        amountMoney: amountMoney,
                        income: income,
                        expenses: expenses
                    )
                    .opacity(isFlipped ? 0.0 : 1.0)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0),
                                      axis: (x: 0, y: 1, z: 0))
                    
                    // BACK (Purchase Alert)
                    if state == .risky {
                        CardBackView(
                            amountMoney: amountMoney,
                            income: income,
                            expenses: expenses,
                            onApprove: handleApprove,
                            onCancel: handleCancel
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .rotation3DEffect(.degrees(isFlipped ? 0 : -180),
                                          axis: (x: 0, y: 1, z: 0))
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .modifier(CardFlipShadow(isFlipped: isFlipped))
                .padding(.top, topSafe + 80)
                
                // Decision toasts
                if state == .approved {
                    toast("Purchase Approved")
                        .padding(.top, topSafe + 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if state == .cancelled {
                    toast("Purchase Cancelled")
                        .padding(.top, topSafe + 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Success checkmark overlay
                if showSuccess {
                    SuccessCheckView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear { startCheck() }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Flow Logic
    private func startCheck() {
        state = .checking
        // Simulate checking purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                state = .risky
                isFlipped = true
            }
        }
    }
    
    private func handleApprove() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            state = .approved
            isFlipped = false
        }
        // Haptic + success animation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            showSuccess = true
        }
        autoClose()
    }
    
    private func handleCancel() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            state = .cancelled
            isFlipped = false
        }
        autoClose()
    }
    
    private func autoClose() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSuccess = false
            }
            onDone()
        }
    }
    
    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Card Back View (Purchase Alert)
private struct CardBackView: View {
    var amountMoney: Int
    var income: Int
    var expenses: Int
    var onApprove: () -> Void
    var onCancel: () -> Void
    
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 }
    private var cardHeight: CGFloat { cardWidth / 1.586 }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black.opacity(0.88), Color.black.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 16) {
                // Title / context
                HStack {
                    Text("Mindful Spending Alert")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                // Single-sentence reasoning
                Text("This purchase may exceed your budget and impact your savings goal of $\(income - expenses) per month.")
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .padding(.trailing, 8)
                
                Spacer()
                
                // Buttons
                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Cancel Purchase")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.14))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: onApprove) {
                        Text("Approve Anyway")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Success Check Animation
private struct SuccessCheckView: View {
    @State private var animate = false
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 72, weight: .semibold))
            .foregroundStyle(.green)
            .scaleEffect(animate ? 1.0 : 0.6)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    animate = true
                }
            }
    }
}

// MARK: - Flip Shadow Helper
private struct CardFlipShadow: ViewModifier {
    let isFlipped: Bool
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(isFlipped ? 0.35 : 0.25), radius: 18, y: 10)
            .rotation3DEffect(.degrees(isFlipped ? 0.0001 : 0), axis: (x: 0, y: 0, z: 0))
    }
}

// MARK: - Previews
#Preview("Card with Floating Feature") {
    FinanceCardContainer(amountMoney: 1200, income: 3000, expenses: 1800)
}

#Preview("Raw Card") {
    FinanceCardView(amountMoney: 1200, income: 3000, expenses: 1800)
}

#Preview("Floating Screen") {
    FloatingCardScreen(amountMoney: 1200, income: 3000, expenses: 1800) { }
}
