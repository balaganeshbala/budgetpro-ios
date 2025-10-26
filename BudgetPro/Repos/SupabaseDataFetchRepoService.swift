//
//  SupabaseDataFetchRepoService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 26/10/25.
//

import Foundation

final class SupabaseDataFetchRepoService: DataFetchRepoService {
    
    private let supabase: SupabaseManager
    
    init() {
        self.supabase = SupabaseManager.shared
    }
    
    func fetchAll<T>(from table: String, filters: [RepoQueryFilter]) async throws -> [T] where T : Decodable {
        var query = supabase.client.from(table).select("*")
        
        // Apply filters
        for filter in filters {
            switch filter.op {
            case .eq:
                query = query.eq(filter.column, value: filter.value)
            case .gte:
                query = query.gte(filter.column, value: filter.value)
            case .lt:
                query = query.lt(filter.column, value: filter.value)
            }
        }
        
        return try await query
                .order("date", ascending: false)
                .order("id", ascending: false)
                .execute()
                .value as [T]
    }
}
