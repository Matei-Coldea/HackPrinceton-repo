//
//  mockSavingsService.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import Foundation

protocol SavingsService {
    func fetchSavings() async throws -> [SavingEntry]
}

final class MockSavingsService: SavingsService {
    func fetchSavings() async throws -> [SavingEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Month offsets with growing amounts to match your mock UI trend
        let months = [-5, -4, -3, -2, -1, 0]
        let amounts: [Decimal] = [30, 60, 90, 140, 240, 320]
        return zip(months, amounts).map { (m, a) in
            SavingEntry(date: cal.date(byAdding: .month, value: m, to: today)!, amount: a)
        }
        .sorted { $0.date < $1.date }
    }
}

