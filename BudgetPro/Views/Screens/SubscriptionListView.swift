import SwiftUI

struct SubscriptionListView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Subscriptions")
                        .font(.appFont(28, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.primary)
                            .clipShape(Circle())
                            .shadow(color: Color.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Summary Card
                        CardView {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Monthly Cost")
                                        .font(.appFont(16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.primary)
                                }
                                
                                Text("₹\(CommonHelpers.formatAmount(viewModel.totalMonthlyCost))")
                                    .font(.appFont(32, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Total recurring expenses per month")
                                    .font(.appFont(12))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Active Subscriptions
                        if viewModel.subscriptions.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.top, 40)
                                
                                Text("No subscriptions yet")
                                    .font(.appFont(16, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text("Add your recurring bills to track them here")
                                    .font(.appFont(14))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Renewals")
                                    .font(.appFont(18, weight: .semibold))
                                    .foregroundColor(.primaryText)
                                    .padding(.horizontal, 4)
                                
                                ForEach(viewModel.upcomingRenewals) { subscription in
                                    SubscriptionRowView(subscription: subscription)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if let index = viewModel.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                                                    viewModel.deleteSubscription(at: IndexSet(integer: index))
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionView(viewModel: viewModel)
        }
    }
}
