//
//  financeCardView.swift
//  Guardian – Mindful Spending
//
//  Created by Annabella Rinaldi on 11/7/25.
//

import SwiftUI
import AVFoundation   // 🔊 for optional approval sound

// MARK: - Front of Card (unchanged visual, minor layout-safe tweaks)
struct FinanceCardView: View {
    var body: some View {
        let cardWidth = UIScreen.main.bounds.width - 32
        let cardHeight = cardWidth / 1.586

        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [DS.cardGradientStart, DS.cardGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles in background
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: cardWidth * 0.6, y: -50)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: cardWidth * 0.7, y: cardHeight * 0.4)

            VStack(alignment: .leading, spacing: 0) {
                // Top section - Card name and contactless
                HStack {
                    Text("FinanceApp Card")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Contactless icon
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.9))
                        .rotationEffect(.degrees(-45))
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer()

                // Card number section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Card Number")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("•••• •••• •••• 4829")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tracking(2)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // Bottom section - Cardholder & Expiry
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cardholder")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                        Text("ALEX JOHNSON")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .tracking(0.5)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Expires")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .textCase(.uppercase)
                        Text("12/28")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: DS.cardGradientStart.opacity(0.3), radius: 15, y: 8)
        .padding(.horizontal, DS.pad)
    }
}

// MARK: - Domain models (Stripe-ready)
struct GuardianTransaction: Identifiable, Codable {
    let id: UUID
    let merchant: String
    let amountCents: Int
    let category: String
    let localTime: Date

    static func demo() -> GuardianTransaction {
        .init(id: .init(),
              merchant: "Late Night Bites",
              amountCents: 2899,
              category: "Dining Out",
              localTime: .init())
    }
}

enum GuardianDecision {
    case approved
    case risky(reason: RiskReason)
    case declined
}

struct RiskReason: Identifiable, Codable, Hashable {
    let id = UUID()
    let headline: String   // <- single sentence from AI later
    let bullets: [String]
    let ctaHint: String
}

// MARK: - Service protocol (mock now; backend/Stripe later)
protocol GuardianAuthService {
    func evaluate(_ txn: GuardianTransaction, completion: @escaping (GuardianDecision) -> Void)
    func override(_ txn: GuardianTransaction, completion: @escaping (Bool) -> Void)
    func cancel(_ txn: GuardianTransaction, completion: @escaping (Bool) -> Void)
}

// Demo service with compact one-liner (fits on card back)
final class DemoAuthService: GuardianAuthService {
    func evaluate(_ txn: GuardianTransaction, completion: @escaping (GuardianDecision) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            completion(.risky(reason: RiskReason(
                headline: "This purchase exceeds your dining-out budget and may delay your savings goal by a few days.",
                bullets: [],
                ctaHint: ""
            )))
        }
    }
    func override(_ txn: GuardianTransaction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion(true) }
    }
    func cancel(_ txn: GuardianTransaction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { completion(true) }
    }
}

// MARK: - Back of Card (single-line reasoning + clean formatting)
private struct RiskBackView: View {
    let reason: RiskReason
    let onOverride: () -> Void
    let onCancel: () -> Void

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

                // Single-sentence reasoning (placeholder for AI model output)
                Text(reason.headline)
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(2)
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

                    Button(action: onOverride) {
                        Text("Override Anyway")
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

// MARK: - Flip shadow helper
private struct CardFlipShadow: ViewModifier {
    let isFlipped: Bool
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(isFlipped ? 0.35 : 0.25), radius: 18, y: 10)
            .rotation3DEffect(.degrees(isFlipped ? 0.0001 : 0), axis: (x: 0, y: 0, z: 0))
    }
}

// MARK: - Success check + sound
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

private final class SoundPlayer {
    private var player: AVAudioPlayer?
    func playApprove() {
        play(named: "approve") // add approve.caf / approve.mp3 / approve.wav to your bundle
    }
    private func play(named: String) {
        if let url = Bundle.main.url(forResource: named, withExtension: "caf")
            ?? Bundle.main.url(forResource: named, withExtension: "mp3")
            ?? Bundle.main.url(forResource: named, withExtension: "wav") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
            } catch { /* ignore for demo */ }
        }
    }
}

// MARK: - Inline container (under title) that presents the Wallet screen
struct GuardianCardContainer: View {
    @State private var showWallet = false

    private let sidePadding: CGFloat = 16
    private let maxCardWidth: CGFloat = 360

    private var cardWidth: CGFloat {
        min(UIScreen.main.bounds.width - (sidePadding * 2), maxCardWidth)
    }
    private var cardHeight: CGFloat { cardWidth / 1.586 }

    var body: some View {
        FinanceCardView()
            .frame(width: cardWidth, height: cardHeight)
            .onTapGesture { showWallet = true }
            .fullScreenCover(isPresented: $showWallet) {
                WalletAuthScreen {
                    showWallet = false   // return to Home when flow completes
                }
            }
    }
}

// MARK: - Wallet-style full screen auth flow (true Wallet vibe)
struct WalletAuthScreen: View {
    enum FlowState { case idle, authorizing, risky(RiskReason), approved, cancelled }

    // Inject your real service later; demo uses mock
    var service: GuardianAuthService = DemoAuthService()
    var onDone: () -> Void

    @State private var state: FlowState = .idle
    @State private var isFlipped = false
    @State private var showSuccess = false     // ✓ overlay
    private let soundPlayer = SoundPlayer()    // 🔊

    private let useBlurScrim = true
    private let maxCardWidth: CGFloat = 360
    private let sidePadding: CGFloat = 16
    private var cardWidth: CGFloat { UIScreen.main.bounds.width - 32 } // match home size
    private var cardHeight: CGFloat { cardWidth / 1.586 }

    private let txn: GuardianTransaction = .demo()

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

                // Card near the top (Wallet position)
                ZStack {
                    // FRONT
                    FinanceCardView()
                        .opacity(isFlipped ? 0.0 : 1.0)
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0),
                                          axis: (x: 0, y: 1, z: 0))

                    // BACK (rationale + actions)
                    if case .risky(let reason) = state {
                        RiskBackView(
                            reason: reason,
                            onOverride: handleOverride,
                            onCancel: handleCancel
                        )
                        .frame(width: cardWidth, height: cardHeight) // keep exact size
                        .rotation3DEffect(.degrees(isFlipped ? 0 : -180),
                                          axis: (x: 0, y: 1, z: 0))
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .modifier(CardFlipShadow(isFlipped: isFlipped))
                .padding(.top, topSafe + 80)

                // Decision toasts
                if case .approved = state {
                    toast("Approved")
                        .padding(.top, topSafe + 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if case .cancelled = state {
                    toast("Cancelled")
                        .padding(.top, topSafe + 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ✓ Success overlay (center)
                if showSuccess {
                    SuccessCheckView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear { startAuthorize() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Flows
    private func startAuthorize() {
        state = .authorizing
        service.evaluate(txn) { decision in
            switch decision {
            case .approved:
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    state = .approved
                }
                autoClose()
            case .risky(let reason):
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    state = .risky(reason)
                    isFlipped = true
                }
            case .declined:
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    state = .cancelled
                }
                autoClose()
            }
        }
    }

    private func handleOverride() {
        service.override(txn) { ok in
            guard ok else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                state = .approved
                isFlipped = false
            }
            // Haptic + sound + ✓
            playApproveFeedback()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showSuccess = true
            }
            autoClose()
        }
    }

    private func handleCancel() {
        service.cancel(txn) { _ in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                state = .cancelled
                isFlipped = false
            }
            autoClose()
        }
    }

    private func autoClose() {
        // brief toast/✓, then return to Home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSuccess = false
            }
            onDone()
        }
    }

    // MARK: - Feedback helpers
    private func playApproveFeedback() {
        // Haptic success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        // Optional sound
        soundPlayer.playApprove()
    }

    // MARK: - UI helper
    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Previews
#Preview("Wallet Flow") {
    WalletAuthScreen { }
}

#Preview("Inline Card") {
    GuardianCardContainer()
}

#Preview("Raw Card") {
    FinanceCardView()
}
