//
//  AddEditGoalView.swift
//  Guardian
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import SwiftUI

struct AddEditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: FinancialGoalsViewModel
    
    var existingGoal: FinancialGoalItem?
    
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var currentAmount = ""
    @State private var selectedCategory: GoalCategory = .general
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var notes = ""
    
    var isEditing: Bool {
        existingGoal != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $title)
                        .autocorrectionDisabled()
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Target Amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Current Amount", text: $currentAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker(
                            "Deadline",
                            selection: $deadline,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Timeline")
                } footer: {
                    if hasDeadline {
                        Text("Set a target date to help you stay on track")
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        saveGoal()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let goal = existingGoal {
                    loadExistingGoal(goal)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && 
        !targetAmount.isEmpty &&
        Decimal(string: targetAmount) != nil &&
        (currentAmount.isEmpty || Decimal(string: currentAmount) != nil)
    }
    
    private func saveGoal() {
        guard let target = Decimal(string: targetAmount) else { return }
        let current = Decimal(string: currentAmount) ?? 0
        
        let goal = FinancialGoalItem(
            id: existingGoal?.id ?? UUID(),
            title: title,
            targetAmount: target,
            currentAmount: current,
            deadline: hasDeadline ? deadline : nil,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            createdDate: existingGoal?.createdDate ?? Date(),
            isCompleted: current >= target
        )
        
        if isEditing {
            vm.updateGoal(goal)
        } else {
            vm.addGoal(goal)
        }
        
        dismiss()
    }
    
    private func loadExistingGoal(_ goal: FinancialGoalItem) {
        title = goal.title
        targetAmount = String(describing: goal.targetAmount)
        currentAmount = String(describing: goal.currentAmount)
        selectedCategory = goal.category
        hasDeadline = goal.deadline != nil
        deadline = goal.deadline ?? Date()
        notes = goal.notes ?? ""
    }
}

// MARK: - Goal Detail View

struct GoalDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: FinancialGoalsViewModel
    let goal: FinancialGoalItem
    
    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var showingProgressUpdate = false
    @State private var newProgressAmount = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        // Category Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: goal.category.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(categoryColor)
                        }
                        
                        VStack(spacing: 4) {
                            Text(goal.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(goal.category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if goal.isCompleted {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Goal Completed!")
                            }
                            .font(.headline)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                    .padding(.vertical, 24)
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress")
                            .font(.headline)
                            .padding(.horizontal, DS.pad)
                        
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(currencyString(goal.currentAmount))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(categoryColor)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Target")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(currencyString(goal.targetAmount))
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * goal.progress)
                                }
                            }
                            .frame(height: 16)
                            
                            HStack {
                                Text("\(goal.progressPercentage)% Complete")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(categoryColor)
                                
                                Spacer()
                                
                                Text("\(currencyString(goal.remainingAmount)) to go")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !goal.isCompleted {
                                Button {
                                    newProgressAmount = String(describing: goal.currentAmount)
                                    showingProgressUpdate = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Update Progress")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(categoryColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
                        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        .padding(.horizontal, DS.pad)
                    }
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                            .padding(.horizontal, DS.pad)
                        
                        VStack(spacing: 0) {
                            DetailRow(
                                icon: "calendar",
                                label: "Created",
                                value: formatDate(goal.createdDate)
                            )
                            
                            if let deadline = goal.deadline {
                                Divider().padding(.leading, 52)
                                
                                DetailRow(
                                    icon: "flag.fill",
                                    label: "Deadline",
                                    value: formatDate(deadline),
                                    valueColor: daysUntilDeadlineColor
                                )
                                
                                if let days = goal.daysRemaining {
                                    Divider().padding(.leading, 52)
                                    
                                    DetailRow(
                                        icon: "clock",
                                        label: "Time Remaining",
                                        value: daysRemainingText(days),
                                        valueColor: daysUntilDeadlineColor
                                    )
                                }
                            }
                            
                            if let notes = goal.notes, !notes.isEmpty {
                                Divider().padding(.leading, 52)
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "note.text")
                                        .font(.body)
                                        .foregroundStyle(categoryColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(notes)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: DS.radius).fill(DS.surfaceElevated))
                        .overlay(RoundedRectangle(cornerRadius: DS.radius).stroke(DS.outline))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        .padding(.horizontal, DS.pad)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            showingEdit = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Goal")
                            }
                            .font(.headline)
                            .foregroundColor(DS.cardGradientStart)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DS.cardGradientStart.opacity(0.1))
                            )
                        }
                        
                        Button {
                            showingDelete = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Goal")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, DS.pad)
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddEditGoalView(vm: vm, existingGoal: goal)
            }
            .alert("Update Progress", isPresented: $showingProgressUpdate) {
                TextField("Amount", text: $newProgressAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { }
                Button("Update") {
                    if let amount = Decimal(string: newProgressAmount) {
                        vm.updateGoalProgress(goal.id, newAmount: amount)
                        dismiss()
                    }
                }
            } message: {
                Text("Enter the new amount saved for this goal")
            }
            .alert("Delete Goal", isPresented: $showingDelete) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    vm.deleteGoal(goal)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(goal.title)'? This action cannot be undone.")
            }
        }
    }
    
    private var categoryColor: Color {
        switch goal.category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "pink": return .pink
        case "teal": return .teal
        default: return .gray
        }
    }
    
    private var daysUntilDeadlineColor: Color {
        guard let days = goal.daysRemaining else { return .primary }
        if days < 0 { return .red }
        if days < 7 { return .orange }
        return .primary
    }
    
    private func daysRemainingText(_ days: Int) -> String {
        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "1 day remaining"
        } else {
            return "\(days) days remaining"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func currencyString(_ decimal: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        let num = NSDecimalNumber(decimal: decimal)
        return formatter.string(from: num) ?? "$0"
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(valueColor)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview("Add Goal") {
    AddEditGoalView(vm: FinancialGoalsViewModel())
}
