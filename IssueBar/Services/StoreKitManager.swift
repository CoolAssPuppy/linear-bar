import Foundation
import StoreKit
import os.log

/// Product identifiers for IAP
enum ProductIdentifier: String, CaseIterable {
    case coffee = "com.strategicnerds.issuebar.coffee"

    var displayName: String {
        switch self {
        case .coffee: return "Buy Me Coffee"
        }
    }

    var description: String {
        switch self {
        case .coffee: return "Support IssueBar development with a coffee!"
        }
    }
}

/// Manages In-App Purchases
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.issuebar", category: "StoreKit")

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadAttempts = 0
    @Published var errorMessage: String?
    @Published var debugInfo: String = ""

    private var updates: Task<Void, Never>?

    private init() {
        // Listen for transaction updates
        updates = observeTransactionUpdates()

        // Load products
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updates?.cancel()
    }

    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        loadAttempts += 1

        let productIDs = ProductIdentifier.allCases.map { $0.rawValue }
        os_log(.info, log: logger, "Loading products (attempt %d): %{public}@", loadAttempts, productIDs.joined(separator: ", "))

        do {
            let storeProducts = try await Product.products(for: productIDs)
            os_log(.info, log: logger, "Received %d products", storeProducts.count)

            await MainActor.run {
                self.products = storeProducts

                if storeProducts.isEmpty {
                    self.debugInfo = "No products returned. Product ID: \(productIDs.joined(separator: ", ")). Attempts: \(loadAttempts)"
                    os_log(.error, log: logger, "No products returned from App Store")
                } else {
                    self.debugInfo = "Loaded: \(storeProducts.map { "\($0.id) - \($0.displayPrice)" }.joined(separator: ", "))"
                    for product in storeProducts {
                        os_log(.info, log: logger, "Product: %{public}@ - %{public}@", product.id, product.displayPrice)
                    }
                }
                self.isLoading = false
            }
        } catch {
            os_log(.error, log: logger, "Error loading products: %{public}@", error.localizedDescription)

            await MainActor.run {
                self.debugInfo = "Error: \(error.localizedDescription)"

                // Provide more specific error messages
                if let skError = error as? StoreKitError {
                    switch skError {
                    case .networkError:
                        self.errorMessage = "Network error. Please check your internet connection."
                    case .systemError:
                        self.errorMessage = "System error. Please try again later."
                    case .notAvailableInStorefront:
                        self.errorMessage = "Not available in your region."
                    case .notEntitled:
                        self.errorMessage = "Not entitled to access this product."
                    default:
                        self.errorMessage = "Failed to load: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Failed to load products. Please try again."
                }
                self.isLoading = false
            }
        }
    }

    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        let result = try await product.purchase()

        DispatchQueue.main.async {
            self.isLoading = false
        }

        switch result {
        case .success(let verification):
            // Check verification result
            let transaction = try checkVerified(verification)

            // Update purchased products
            await updatePurchasedProducts()

            // Finish the transaction
            await transaction.finish()

            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    /// Restore purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Check if a product has been purchased
    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    /// Update purchased products from current entitlements
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }

        DispatchQueue.main.async {
            self.purchasedProductIDs = purchased
        }
    }

    /// Observe transaction updates
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                // Update purchased products
                await updatePurchasedProducts()

                // Finish transaction
                await transaction.finish()
            }
        }
    }

    /// Verify a transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

/// Store errors
enum StoreError: Error {
    case failedVerification

    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Transaction failed verification"
        }
    }
}
