import SwiftUI
import Combine

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = [] {
        didSet {
            saveSubscriptions()
        }
    }
    
    private let saveKey = "saved_subscriptions"
    
    init() {
        loadSubscriptions()
    }
    
    // MARK: - CRUD
    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
    }
    
    func deleteSubscription(at offsets: IndexSet) {
        subscriptions.remove(atOffsets: offsets)
    }
    
    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        }
    }
    
    // MARK: - Calculations
    var totalMonthlyCost: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyEquivalentAmount }
    }
    
    var upcomingRenewals: [Subscription] {
        subscriptions.sorted { $0.nextRenewalDate < $1.nextRenewalDate }
    }
    
    // MARK: - Persistence
    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadSubscriptions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            subscriptions = decoded
        }
    }
}
