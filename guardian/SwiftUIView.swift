import SwiftUI
import Charts

// MARK: - Data Models
struct MonthlyData: Codable, Identifiable {
    let id = UUID()
    let month: String
    let budget: Double
    let spending: Double
    let groceries_spending: Double
    let dining_out: Double
    let shopping: Double
    let transportation: Double
    let entertainment: Double
}

struct analyticsData: Codable {
    let monthlyData: [MonthlyData]
}

struct SpendingCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let spent: Double
    let budget: Double
    let transactions: Int
    let trend: Double
    let color: Color
    let sparklineData: [Double]
    
    var percentage: Double {
        (spent / budget) * 100
    }
    
    var isOverBudget: Bool {
        spent > budget
    }
}

// MARK: - JSON Loader
func loadAnalyticsData() -> [MonthlyData] {
    guard let url = Bundle.main.url(forResource: "analyticsData", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode(analyticsData.self, from: data) else {
        print("❌ Failed to load analyticsData.json")
        return []
    }
    return decoded.monthlyData
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: SpendingCategory
    let isExpanded: Bool
    let isHovered: Bool
    let animationDelay: Double

    @State private var progressAnimation: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text("\(category.icon)")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(category.name)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: category.isOverBudget
                                                ? [.red, .orange]
                                                : [category.color, category.color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(progressAnimation * geometry.size.width, geometry.size.width), height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("$\(Int(category.spent)) / $\(Int(category.budget))")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(category.percentage))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(category.isOverBudget ? .red : category.color)
                        }
                    }
                }
            }
            .padding(16)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 24) {
                        DetailMetric(icon: "creditcard.fill", label: "Transactions", value: "\(category.transactions)", color: category.color)
                        DetailMetric(icon: "chart.line.uptrend.xyaxis", label: "Avg/Transaction", value: "$\(Int(category.spent / Double(category.transactions)))", color: category.color)
                        DetailMetric(icon: category.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.shield.fill", label: "Status", value: category.isOverBudget ? "Over" : "Good", color: category.isOverBudget ? .red : .green)
                    }
                    .padding(.horizontal, 16)
                    
                    SparklineChart(data: category.sparklineData, color: category.color)
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(animationDelay)) {
                progressAnimation = min(CGFloat(category.percentage) / 100, 1.1)
            }
        }
    }
}

// MARK: - Analytics View
struct AnalyticsTableView: View {
    @State private var expandedRow: UUID?
    @State private var animateIn = false
    @State private var selectedMonth = "November"
    
    let months = Calendar.current.monthSymbols
    let analytics = loadAnalyticsData()
    
    var selectedData: MonthlyData? {
        analytics.first(where: { $0.month == selectedMonth })
    }
    
    var categories: [SpendingCategory] {
        guard let data = selectedData else { return [] }
        return [
            SpendingCategory(name: "Dining Out", icon: "🍔", spent: data.dining_out, budget: data.budget * 0.2, transactions: 6, trend: -5, color: .orange, sparklineData: [30, 40, 60, data.dining_out]),
            SpendingCategory(name: "Shopping", icon: "🛍️", spent: data.shopping, budget: data.budget * 0.15, transactions: 5, trend: 8, color: .pink, sparklineData: [80, 100, 120, data.shopping]),
            SpendingCategory(name: "Transportation", icon: "🚗", spent: data.transportation, budget: data.budget * 0.15, transactions: 4, trend: -2, color: .blue, sparklineData: [40, 50, 70, data.transportation]),
            SpendingCategory(name: "Entertainment", icon: "📽️", spent: data.entertainment, budget: data.budget * 0.15, transactions: 3, trend: 5, color: .purple, sparklineData: [50, 60, 80, data.entertainment]),
            SpendingCategory(name: "Groceries", icon: "🛒", spent: data.groceries_spending, budget: data.budget * 0.35, transactions: 8, trend: -3, color: .green, sparklineData: [150, 200, 250, data.groceries_spending])
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                LazyVStack(spacing: 12) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryRow(
                            category: category,
                            isExpanded: expandedRow == category.id,
                            isHovered: false,
                            animationDelay: Double(index) * 0.1
                        )
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                expandedRow = expandedRow == category.id ? nil : category.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        let totalSpent = categories.reduce(0) { $0 + $1.spent }
        let totalBudget = categories.reduce(0) { $0 + $1.budget }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analytics")
                    .font(.system(size: 25, weight: .bold))
                Spacer()
                Picker("Select a month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(month).tag(month)
                    }
                }
                .pickerStyle(.menu)
                .tint(.black)
            }
            
            HStack(spacing: 16) {
                StatCard(title: "Total Spent", value: "$\(Int(totalSpent))", subtitle: selectedMonth, color: .blue, icon: "dollarsign.circle.fill")
                StatCard(title: "Budget Left", value: "$\(Int(totalBudget - totalSpent))", subtitle: "Remaining", color: .green, icon: "checkmark.circle.fill")
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 24, weight: .bold))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Detail Metric + Sparkline
struct DetailMetric: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.system(size: 15, weight: .bold))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SparklineChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let maxValue = data.max() ?? 1
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                let stepY = geometry.size.height / CGFloat(maxValue)
                
                path.move(to: CGPoint(x: 0, y: geometry.size.height - CGFloat(data[0]) * stepY))
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - CGFloat(value) * stepY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    AnalyticsTableView()
}
