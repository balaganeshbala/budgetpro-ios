// TransactionRepoService.swift
import Foundation

enum TransactionType {
    case expense
    case income
    case majorExpense
}

struct RepoQueryFilter {
    let column: String
    let op: RepoQueryOperator
    let value: String
}

enum RepoQueryOperator: String {
    case eq, gte, lt
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

protocol DataFetchRepoService {
    // Fetch
    func fetchAll<T: Decodable>(
        from table: String,
        filters: [RepoQueryFilter],
        orderBy: String?
    ) async throws -> [T]
}

extension DataFetchRepoService {
    func fetchAll<T: Decodable>(
        from table: String,
        filters: [RepoQueryFilter]
    ) async throws -> [T] {
        return try await fetchAll(from: table, filters: filters, orderBy: "date")
    }
}
