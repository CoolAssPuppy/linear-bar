import SwiftUI
import StoreKit

struct CoffeeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var showThankYou = false
    @State private var isPurchasing = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            Spacer()

            // Content
            VStack(spacing: 24) {
                Text("LinearBar is free.")
                    .font(.title3)

                Text("But you can buy me coffee ☕")
                    .font(.title2)
                    .fontWeight(.medium)

                if showThankYou {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Thank you for your support!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your coffee has been received 🎉")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Product list
                    if storeManager.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else if let coffeeProduct = storeManager.products.first(where: { $0.id == ProductIdentifier.coffee.rawValue }) {
                        VStack(spacing: 16) {
                            // Product display
                            VStack(spacing: 8) {
                                Text(coffeeProduct.displayName)
                                    .font(.headline)

                                Text(coffeeProduct.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            // Purchase button
                            Button(action: {
                                Task {
                                    await purchaseCoffee(coffeeProduct)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "cup.and.saucer.fill")
                                    Text("Buy Coffee - \(coffeeProduct.displayPrice)")
                                }
                                .font(.title3)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .disabled(isPurchasing)
                            .controlSize(.large)

                            if isPurchasing {
                                ProgressView()
                                    .padding(.top, 8)
                            }

                            // Already purchased indicator
                            if storeManager.isPurchased(coffeeProduct.id) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Already purchased - Thank you!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                    } else {
                        // Product not loaded - show retry option with explanation
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            VStack(spacing: 8) {
                                Text("Unable to Load Purchase")
                                    .font(.headline)

                                Text("The in-app purchase couldn't be loaded from the App Store.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            Button(action: {
                                Task {
                                    await storeManager.loadProducts()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Try Again")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)

                            // Show debug info in a collapsible section
                            DisclosureGroup("Troubleshooting Info") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Product ID:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(ProductIdentifier.coffee.rawValue)
                                        .font(.caption.monospaced())
                                        .textSelection(.enabled)

                                    if !storeManager.debugInfo.isEmpty {
                                        Text("Status:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(storeManager.debugInfo)
                                            .font(.caption.monospaced())
                                            .textSelection(.enabled)
                                    }

                                    Text("Load attempts: \(storeManager.loadAttempts)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Divider()

                                    Text("Common causes:")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                    Text("- App Store Connect IAP not approved\n- Paid Apps agreement not accepted\n- Network connectivity issues\n- App not signed correctly")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        }
                    }

                    // Error message
                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // Restore button
                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }
                    .buttonStyle(.link)
                    .padding(.top, 16)
                }
            }
            .padding()

            Spacer()

            // Footer note
            VStack(spacing: 8) {
                Text("All purchases are one-time and non-consumable")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Thank you for supporting independent development!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .frame(width: 500, height: 600)
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Support LinearBar")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Buy Me Coffee")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(.regularMaterial)
    }

    private func purchaseCoffee(_ product: Product) async {
        isPurchasing = true

        do {
            let transaction = try await storeManager.purchase(product)

            if transaction != nil {
                withAnimation {
                    showThankYou = true
                }

                // Hide thank you message after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showThankYou = false
                    }
                }
            }
        } catch {
            // Purchase failed - error will be shown via errorMessage if needed
        }

        isPurchasing = false
    }
}

struct CoffeeView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeView()
    }
}
