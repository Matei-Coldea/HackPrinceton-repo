//
//  notificationsView.swift
//  financeApp
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    AlertNotificationRow(
                        emoji: "🚨",
                        title: "You're $45 over budget at Target",
                        subtitle: "Weekends at this location = overspending",
                        time: "5 min ago",
                        urgency: .high
                    )
                    
                    AlertNotificationRow(
                        emoji: "⏰",
                        title: "Late-night shopping alert",
                        subtitle: "You return 80% of purchases made after 9 PM",
                        time: "1h ago",
                        urgency: .medium
                    )
                    
                    AlertNotificationRow(
                        emoji: "💸",
                        title: "DoorDash = $38 down the drain",
                        subtitle: "You have leftovers that expire tomorrow",
                        time: "2h ago",
                        urgency: .medium
                    )
                } header: {
                    Text("RIGHT NOW")
                }
                
                Section {
                    WinNotificationRow(
                        emoji: "🎉",
                        title: "Starbucks avoided: +$127 this month",
                        subtitle: "You're crushing your trigger locations",
                        time: "Yesterday"
                    )
                    
                    TipNotificationRow(
                        emoji: "🌧️",
                        title: "Rain = 3x more delivery spending",
                        subtitle: "Tomorrow's forecast: scattered showers",
                        time: "2 days ago"
                    )
                    
                    AlertNotificationRow(
                        emoji: "👥",
                        title: "Your friends are out - you have $18 left",
                        subtitle: "Stay strong. Your budget ends in 5 days",
                        time: "3 days ago",
                        urgency: .low
                    )
                } header: {
                    Text("THIS WEEK")
                }
                
                Section {
                    WinNotificationRow(
                        emoji: "🔥",
                        title: "4 out of 5 impulse buys avoided",
                        subtitle: "Saved $203 by ignoring spending triggers",
                        time: "Last week"
                    )
                } header: {
                    Text("HISTORY")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum NotificationUrgency {
    case low, medium, high
    
    var badgeColor: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct AlertNotificationRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let time: String
    let urgency: NotificationUrgency
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Circle()
                        .fill(urgency.badgeColor)
                        .frame(width: 8, height: 8)
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(time.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct WinNotificationRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(time.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct TipNotificationRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(time.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NotificationsView()
}

