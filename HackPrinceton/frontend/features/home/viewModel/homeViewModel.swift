//
//  homeViewModel.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var entries: [SavingEntry] = []
    @Published var error: String?

    private let service: SavingsService

    init(service: SavingsService = MockSavingsService()) {  // mock only
        self.service = service
    }

    func load() {
        isLoading = true
        Task {
            do {
                entries = try await service.fetchSavings()
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    var totalSaved: Decimal { entries.reduce(0) { $0 + $1.amount } }

    var sinceDate: Date? { entries.first?.date }

    var cumulative: [(Date, Decimal)] {
        var run: Decimal = 0
        return entries.map { e in run += e.amount; return (e.date, run) }
    }
}
