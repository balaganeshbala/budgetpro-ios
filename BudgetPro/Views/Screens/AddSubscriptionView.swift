import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SubscriptionViewModel
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var startDate: Date = Date()
    @State private var notes: String = ""
    @State private var colorHex: String = "#0AFF99" // Default Mint
    
    @State private var showBillingCyclePicker = false
    @State private var showDatePicker = false // Not strictly needed with standard DatePicker, but good for custom dialog
    
    // Simple color palette
    let colors: [String] = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#00C7BE", // Teal
        "#30B0C7", // Blue
        "#32ADE6", // Light Blue
        "#007AFF", // System Blue
        "#5856D6", // Indigo
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#A2845E"  // Brown
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.cardBackground)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Add Subscription")
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.clear)
                        .padding(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Name
                        AppTextField(
                            hint: "Subscription Name",
                            iconName: "tag.fill",
                            text: $name,
                            submitLabel: .next,
                            textCapitalization: .words
                        )
                        
                        // Amount
                        AppTextField(
                            hint: "Amount",
                            iconName: "indianrupeesign.circle.fill",
                            text: $amount,
                            keyboardType: .decimalPad,
                            submitLabel: .done
                        )
                        
                        // Billing Cycle
                        DropdownSelectorField(
                            label: "Billing Cycle",
                            iconName: "arrow.triangle.2.circlepath",
                            selectedItem: billingCycle,
                            itemDisplayName: { $0.displayName },
                            onTap: { showBillingCyclePicker = true }
                        )
                        
                        // Start Date
                        VStack(alignment: .leading, spacing: 10) {
                            Text("First Bill Date")
                                .font(.appFont(14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Color Code")
                                .font(.appFont(14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex) ?? .gray)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                                            )
                                            .onTapGesture {
                                                colorHex = hex
                                            }
                                    }
                                }
                                .padding(4)
                            }
                        }
                        
                        // Notes
                        AppTextField(
                            hint: "Notes (Optional)",
                            iconName: "note.text",
                            text: $notes,
                            submitLabel: .done
                        )
                        
                        // Save Button
                        Button(action: saveSubscription) {
                            Text("Save Subscription")
                                .font(.appFont(18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.primary)
                                .cornerRadius(16)
                                .shadow(color: Color.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.top, 10)
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            
            // Picker Overlay
            if showBillingCyclePicker {
                DropdownPickerDialog(
                    title: "Select Billing Cycle",
                    items: BillingCycle.allCases,
                    selectedItem: billingCycle,
                    onItemSelected: { billingCycle = $0 },
                    itemDisplayName: { $0.displayName },
                    isPresented: $showBillingCyclePicker
                )
            }
        }
    }
    
    private func saveSubscription() {
        guard !name.isEmpty, let amountValue = Double(amount) else { return }
        
        let newSubscription = Subscription(
            name: name,
            amount: amountValue,
            billingCycle: billingCycle,
            startDate: startDate,
            notes: notes.isEmpty ? nil : notes,
            colorHex: colorHex
        ) // ID is auto-generated
        
        viewModel.addSubscription(newSubscription)
        dismiss()
    }
}
