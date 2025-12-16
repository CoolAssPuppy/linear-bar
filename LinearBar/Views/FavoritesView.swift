import SwiftUI
import os.log

/// View displaying user's favorite items from Linear
struct FavoritesView: View {
    @State private var favorites: [Favorite] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCompletedItems = true
    @State private var showCanceledItems = false
    @State private var sortOrder: SortOrder = .updatedNewest

    private var filterOptions: ItemFilter.FilterOptions {
        ItemFilter.FilterOptions(showCompleted: showCompletedItems, showCanceled: showCanceledItems)
    }

    private var nonFolderFavorites: [Favorite] {
        let filtered = favorites.filter { favorite in
            guard !isFolder(favorite) else { return false }

            // Get the linear item to filter
            if let item = getLinearItem(from: favorite) {
                return ItemFilter.shouldInclude(item, options: filterOptions)
            }
            // Include non-item favorites (custom views, cycles, labels)
            return true
        }

        return filtered.sorted { fav1, fav2 in
            guard let item1 = getLinearItem(from: fav1),
                  let item2 = getLinearItem(from: fav2) else {
                return false
            }
            return ItemFilter.compare(item1, item2, by: sortOrder)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingStateView("Loading favorites...")
            } else if AppSettings.shared.accounts.isEmpty {
                NoAccountView(message: "Connect your Linear account to see your favorites, issues, and projects.")
            } else if let error = errorMessage {
                ErrorStateView(title: "Error loading favorites", message: error, onRetry: loadFavorites)
            } else if nonFolderFavorites.isEmpty {
                EmptyStateView(
                    icon: "star.slash",
                    title: "No favorites yet",
                    subtitle: "Star items in Linear to see them here"
                )
            } else {
                contentView
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                syncSettingsFromAppSettings()
                loadFavorites()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            syncSettingsFromAppSettings()
        }
    }

    private func syncSettingsFromAppSettings() {
        let settings = AppSettings.shared
        showCompletedItems = settings.showCompletedItems
        showCanceledItems = settings.showCanceledItems
        sortOrder = settings.sortOrder
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(nonFolderFavorites) { favorite in
                    favoriteRow(for: favorite)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func favoriteRow(for favorite: Favorite) -> some View {
        if let issue = favorite.issue {
            ItemRow(issue: issue, accountColor: AppSettings.shared.primaryAccountColor)
        } else if let project = favorite.project {
            ItemRow(project: project, accountColor: AppSettings.shared.primaryAccountColor)
        } else if let initiative = favorite.initiative {
            ItemRow(initiative: initiative, accountColor: AppSettings.shared.primaryAccountColor)
        } else if let customView = favorite.customView {
            GenericFavoriteRowView(
                name: customView.name,
                icon: customView.icon,
                type: "Custom View",
                accountColor: AppSettings.shared.primaryAccountColor,
                onTap: { openLinearURL(path: "view/\(customView.id)") }
            )
        } else if let cycle = favorite.cycle {
            GenericFavoriteRowView(
                name: cycle.name,
                icon: cycle.icon,
                type: "Cycle",
                accountColor: AppSettings.shared.primaryAccountColor,
                onTap: { openLinearURL(path: "cycle/\(cycle.id)") }
            )
        } else if let label = favorite.label {
            GenericFavoriteRowView(
                name: label.name,
                icon: label.icon,
                type: "Label",
                accountColor: AppSettings.shared.primaryAccountColor,
                onTap: { openLinearURL(path: "label/\(label.id)") }
            )
        }
    }

    // MARK: - Helpers

    private func isFolder(_ favorite: Favorite) -> Bool {
        favorite.issue == nil &&
        favorite.project == nil &&
        favorite.initiative == nil &&
        favorite.customView == nil &&
        favorite.cycle == nil &&
        favorite.label == nil &&
        favorite.folderName != nil
    }

    private func getLinearItem(from favorite: Favorite) -> (any LinearItem)? {
        favorite.issue ?? favorite.project ?? favorite.initiative
    }

    private func openLinearURL(path: String) {
        guard let orgSlug = AppSettings.shared.primaryOrganizationSlug,
              let url = URL(string: "https://linear.app/\(orgSlug)/\(path)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Data Loading

    private func loadFavorites() {
        // Check for demo mode first
        let isDemoMode = TestDataProvider.isUITesting

        // In demo mode, use a dummy token since the API will return test data
        let accessToken: String
        let accountEmail: String

        if isDemoMode {
            accessToken = "demo-token"
            accountEmail = "demo@example.com"
        } else {
            guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
                  let token = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
                errorMessage = "No authenticated account found. Please sign in."
                return
            }
            accessToken = token
            accountEmail = account.email
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedFavorites = try await LinearAPI.shared.fetchFavorites(accessToken: accessToken, accountEmail: accountEmail)
                await MainActor.run {
                    self.favorites = loadedFavorites
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    AppLogger.error("Error loading favorites", log: AppLogger.ui, error: error)
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Generic Favorite Row Component

struct GenericFavoriteRowView: View {
    let name: String
    let icon: String?
    let type: String
    let accountColor: String?
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let color = accountColor {
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        iconView

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(type)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isHovered {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = icon, !icon.isEmpty {
            if icon.count == 1 {
                Text(icon)
                    .font(.system(size: 14))
            } else {
                Image(systemName: SFSymbolMapper.sfSymbol(for: icon))
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
            }
        } else {
            Image(systemName: SFSymbolMapper.sfSymbolForFavoriteType(type))
                .font(.system(size: 16))
                .foregroundColor(.purple)
        }
    }
}
