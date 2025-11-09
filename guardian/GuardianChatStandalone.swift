//
//  GuardianChatStandalone.swift
//  
//
//  Created by Annabella Rinaldi on 11/8/25.
//
//
//  This single file contains:
//  - SwiftUI app + chat screen
//  - OpenAI client (Chat Completions API via URLSession)
//  - Lightweight memory store (spending summary + goals)
//  - Memory extraction pass to persist user-mentioned goals/context
//
//  HOW TO USE:
//  1) Put your OpenAI API key in OPENAI_API_KEY below.
//  2) Build & run on iOS 16+.
//  3) Type to chat; the assistant uses your spending summary & goals,
//     and it learns new goals you mention.
//
//  NOTES:
//  - This is a demo. In production, keep API keys on server and proxy requests.
//  - Replace the initial spending summary with a real computed summary later.
//

import SwiftUI
import Foundation

// =====================================================
// MARK: - CONFIG
// =====================================================

private let OPENAI_API_KEY = "<PUT_YOUR_OPENAI_API_KEY_HERE>"

/// Keep the system prompt focused and stable.
private let SYSTEM_PROMPT = """
You are Guardian, a mindful spending coach.

Context you ALWAYS receive:
- user_spending_summary: a compact, rolling summary of recent spending patterns
- user_goals: a short list of explicit savings/budget goals (with deadlines if given)

Behavior:
1) Be concise and pragmatic. Offer 1–3 concrete suggestions.
2) When advising, reference the user's patterns/goals specifically.
3) If asked for numbers, give safe, simple estimates (no over-precision).
4) If unsure, ask exactly one clarifying question.

NEVER invent transactions or goals. Use only the provided summaries/goals or what the user just said.
"""

// =====================================================
// MARK: - DOMAIN MODELS (Profile Memory & Chat)
// =====================================================

struct SpendingProfile: Codable {
    var spendingSummary: String         // e.g., "Dining +18% vs. avg; late-night Fri orders $25–35"
    var goals: [UserGoal]
}

struct UserGoal: Codable, Hashable {
    var goal: String                    // e.g., "Save $2,000 by Feb 1"
    var deadlineISO8601: String?        // optional ISO date
}

struct ChatTurn: Identifiable {
    let id = UUID()
    let role: String  // "user" | "assistant" | "system"
    let content: String
}

// =====================================================
// MARK: - OPENAI CLIENT (Chat Completions)
// =====================================================

final class OpenAIClient {
    private let apiKey: String
    /// Choose a capable chat model. You can swap as needed.
    private let model: String = "gpt-4.1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // Request/Response shapes for /v1/chat/completions
    struct ChatRequest: Codable {
        struct Msg: Codable { let role: String; let content: String }
        let model: String
        let messages: [Msg]
        let temperature: Double?
    }

    struct ChatResp: Codable {
        struct Choice: Codable {
            struct Msg: Codable { let role: String; let content: String }
            let index: Int
            let finish_reason: String?
            let message: Msg
        }
        let id: String
        let choices: [Choice]
    }

    func chat(messages: [ChatRequest.Msg], temperature: Double = 0.2) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(model: model, messages: messages, temperature: temperature)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let decoded = try JSONDecoder().decode(ChatResp.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}

// =====================================================
// MARK: - MEMORY EXTRACTOR (Second pass)
// =====================================================

/// We ask the model to ONLY emit JSON deltas for profile updates.
struct MemoryDelta: Codable {
    var newSpendingSummary: String?
    var goalsToAdd: [UserGoal]?
}

final class MemoryExtractor {
    let client: OpenAIClient
    init(client: OpenAIClient) { self.client = client }

    func extract(from userMessage: String,
                 assistantReply: String,
                 current: SpendingProfile) async throws -> MemoryDelta? {

        let system = OpenAIClient.ChatRequest.Msg(
            role: "system",
            content: """
Return ONLY compact JSON for memory updates in this schema:
{
  "newSpendingSummary": "<optional replacement string>",
  "goalsToAdd": [{"goal":"<text>", "deadlineISO8601":"<optional>"}]
}
If nothing to change, return {}. Do not include any extra text.
"""
        )

        let user = OpenAIClient.ChatRequest.Msg(
            role: "user",
            content: """
User said: \(userMessage)
Assistant replied: \(assistantReply)

Current summary: \(current.spendingSummary)
Current goals: \(current.goals.map{$0.goal}.joined(separator: "; "))

Extract new/updated goals (savings, budget caps, timelines) and/or an updated spending summary IF the user clarified it.
"""
        )

        let raw = try await client.chat(messages: [system, user], temperature: 0)
        // Be defensive about accidental backticks
        let json = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MemoryDelta.self, from: data)
    }
}

// =====================================================
// MARK: - VIEW MODEL (Orchestrates reply + memory)
// =====================================================

@MainActor
final class GuardianChatVM: ObservableObject {
    @Published var turns: [ChatTurn] = []
    @Published var input: String = ""
    @Published var isSending: Bool = false

    // Start with a simple, fake summary; swap for real computed summary later.
    @Published var profile = SpendingProfile(
        spendingSummary: "Dining spend elevated on Fridays; groceries avg ~$110/week; rideshare 2–3x/week.",
        goals: []
    )

    private let client: OpenAIClient
    private let extractor: MemoryExtractor

    init(apiKey: String) {
        self.client = OpenAIClient(apiKey: apiKey)
        self.extractor = MemoryExtractor(client: client)
    }

    func send() async {
        let userText = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        input = ""
        isSending = true
        turns.append(ChatTurn(role: "user", content: userText))

        // Build messages with system + memory context + running chat
        let sys = OpenAIClient.ChatRequest.Msg(role: "system", content: SYSTEM_PROMPT)
        let memory = OpenAIClient.ChatRequest.Msg(
            role: "system",
            content: """
user_spending_summary: \(profile.spendingSummary)
user_goals: \(profile.goals.map{$0.goal}.joined(separator: "; "))
"""
        )

        var msgs: [OpenAIClient.ChatRequest.Msg] = [sys, memory]
        for t in turns { msgs.append(.init(role: t.role, content: t.content)) }

        do {
            let reply = try await client.chat(messages: msgs)
            turns.append(ChatTurn(role: "assistant", content: reply))

            // Memory update pass
            if let delta = try await extractor.extract(from: userText, assistantReply: reply, current: profile) {
                if let s = delta.newSpendingSummary, !s.isEmpty {
                    profile.spendingSummary = s
                }
                if let adds = delta.goalsToAdd, !adds.isEmpty {
                    let existing = Set(profile.goals)
                    profile.goals = Array(existing.union(adds))
                }
            }
        } catch {
            turns.append(ChatTurn(role: "assistant", content: "Sorry — I couldn’t reach the AI just now. Please try again."))
        }

        isSending = false
    }
}

// =====================================================
// MARK: - CHAT UI
// =====================================================

struct GuardianChatView: View {
    @StateObject var vm = GuardianChatVM(apiKey: OPENAI_API_KEY)

    var body: some View {
        VStack(spacing: 0) {
            // Header with current memory snapshot (so you see what the bot "knows")
            VStack(alignment: .leading, spacing: 6) {
                Text("Guardian Chat").font(.title2.bold())
                Text("Summary: \(vm.profile.spendingSummary)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !vm.profile.goals.isEmpty {
                    Text("Goals: " + vm.profile.goals.map { $0.goal }.joined(separator: " • "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.turns) { t in
                            messageBubble(turn: t)
                                .id(t.id)
                        }
                        if vm.isSending {
                            HStack {
                                ProgressView()
                                Text("Thinking…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
                .onChange(of: vm.turns.count) { _ in
                    // Auto-scroll to latest
                    if let last = vm.turns.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            // Composer
            HStack(spacing: 10) {
                TextField("Ask about your spending, goals…", text: $vm.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button(action: { Task { await vm.send() } }) {
                    if vm.isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send").bold()
                    }
                }
                .disabled(vm.isSending || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func messageBubble(turn: ChatTurn) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if turn.role == "assistant" {
                Text("🛡️")
            } else {
                Text("🙂")
            }
            Text(turn.content)
                .padding(10)
                .background(turn.role == "assistant" ? Color(.systemGray6) : Color(.systemBlue).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// =====================================================
// MARK: - APP ENTRY (standalone)
// =====================================================

@main
struct GuardianChatDemoApp: App {
    var body: some Scene {
        WindowGroup {
            GuardianChatView()
        }
    }
}

