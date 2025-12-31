// SupabaseTransactionRepoService.swift
import Foundation

final class SupabaseTransactionRepoService: TransactionRepoService {
    
    private let transactionType: TransactionType
    private let supabase: SupabaseManager
    
    @MainActor
    init(transactionType: TransactionType) {
        self.transactionType = transactionType
        self.supabase = SupabaseManager.shared
    }
    
    func create(
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws {
        let (table, payload) = try await makeInsert(name: name, amount: amount, categoryRaw: categoryRaw, date: date, notes: notes)
        try await supabase.client
            .from(table)
            .insert(payload)
            .execute()
    }
    
    func update(
        id: Int,
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws {
        let (table, payload) = try await makeUpdate(name: name, amount: amount, categoryRaw: categoryRaw, date: date, notes: notes)
        try await supabase.client
            .from(table)
            .update(payload)
            .eq("id", value: id)
            .execute()
    }
    
    func delete(id: Int) async throws {
        let table = tableName()
        try await supabase.client
            .from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Helpers
    
    private func tableName() -> String {
        switch transactionType {
        case .expense: return "expenses"
        case .income: return "incomes" // ensure plural to match existing add flow
        case .majorExpense: return "major_expenses"
        }
    }
    
    private func makeInsert(
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws -> (String, any Encodable) {
        let table = tableName()
        let dateString = formatDateForDatabase(date)
        let userId = try await currentUserId().uuidString
        switch transactionType {
        case .expense:
            return (table, ExpenseInsertData(name: name, amount: amount, category: categoryRaw, date: dateString, userId: userId))
        case .income:
            // incomes use "source" column
            return (table, IncomeInsertData(source: name, amount: amount, category: categoryRaw, date: dateString, userId: userId))
        case .majorExpense:
            let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil
            return (table, MajorExpenseInsertData(name: name, amount: amount, category: categoryRaw, date: dateString, notes: finalNotes, userId: userId))
        }
    }
    
    private func makeUpdate(
        name: String,
        amount: Double,
        categoryRaw: String,
        date: Date,
        notes: String?
    ) async throws -> (String, any Encodable) {
        let table = tableName()
        let amountString = amount.rawValue
        let dateString = formatDateForDatabase(date)
        switch transactionType {
        case .expense:
            return (table, ["name": name, "amount": amountString, "category": categoryRaw, "date": dateString])
        case .income:
            // incomes use "source" column
            return (table, ["source": name, "amount": amountString, "category": categoryRaw, "date": dateString])
        case .majorExpense:
            let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil
            return (table, ["name": name, "amount": amountString, "category": categoryRaw, "date": dateString, "notes": finalNotes])
        }
    }
    
    @MainActor
    private func currentUserId() async throws -> UUID {
        // Prefer reading from SupabaseManager’s currentUser; fallback to session if needed.
        if let id = supabase.currentUser?.id {
            return id
        }
        let session = try await supabase.client.auth.session
        return session.user.id
    }
    
    private func formatDateForDatabase(_ date: Date) -> String {
        // Current inserts elsewhere write "MM/dd/yyyy"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
