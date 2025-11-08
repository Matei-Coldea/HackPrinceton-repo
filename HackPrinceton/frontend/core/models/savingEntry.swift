//
//  savingEntry.swift
//  
//
//  Created by Annabella Rinaldi on 11/7/25.
//
import Foundation

struct SavingEntry: Identifiable, Codable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Decimal  // positive increments = saved added
}

