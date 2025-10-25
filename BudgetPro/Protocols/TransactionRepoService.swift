// TransactionRepoService.swift
import Foundation

enum TransactionType {
    case expense
    case income
    case majorExpense
}

protocol TransactionRepoService {
    // Create
    func create(
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws
    
    // Update
    func update(
        id: Int,
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws
    
    // Delete
    func delete(
        id: Int
    ) async throws
}
