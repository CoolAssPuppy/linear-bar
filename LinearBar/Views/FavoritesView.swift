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

    private var nonFolderFavorites: [Favorite] {
        let filtered = favorites.filter { favorite in
            // Filter out folders
            guard !isFolder(favorite) else { return false }

            // Apply state filters for issues
            if let issue = favorite.issue {
                if let stateType = issue.state?.type {
                    if stateType == "completed" && !showCompletedItems {
                        return false
                    }
                    if stateType == "canceled" && !showCanceledItems {
                        return false
                    }
                }
            }

            // Apply state filters for projects
            if let project = favorite.project {
                if project.state.lowercased() == "completed" && !showCompletedItems {
                    return false
                }
                if project.state.lowercased() == "canceled" && !showCanceledItems {
                    return false
                }
            }

            // Apply state filters for initiatives
            if let initiative = favorite.initiative {
                if initiative.status?.lowercased() == "completed" && !showCompletedItems {
                    return false
                }
            }

            return true
        }

        // Apply sort order
        return filtered.sorted { fav1, fav2 in
            let item1 = getLinearItem(from: fav1)
            let item2 = getLinearItem(from: fav2)

            switch sortOrder {
            case .createdNewest:
                let date1 = item1?.createdAt ?? Date.distantPast
                let date2 = item2?.createdAt ?? Date.distantPast
                return date1 > date2
            case .createdOldest:
                let date1 = item1?.createdAt ?? Date.distantPast
                let date2 = item2?.createdAt ?? Date.distantPast
                return date1 < date2
            case .updatedNewest:
                let date1 = item1?.updatedAt ?? Date.distantPast
                let date2 = item2?.updatedAt ?? Date.distantPast
                return date1 > date2
            case .updatedOldest:
                let date1 = item1?.updatedAt ?? Date.distantPast
                let date2 = item2?.updatedAt ?? Date.distantPast
                return date1 < date2
            case .dueDate:
                // Get due dates - could be from Issue, Project, or Initiative
                let dueDate1 = getDueDate(from: fav1)
                let dueDate2 = getDueDate(from: fav2)

                // Items with due dates come first, sorted by due date
                // Items without due dates come after, sorted by created date (newest first)
                switch (dueDate1, dueDate2) {
                case (.some(let date1), .some(let date2)):
                    // Both have due dates - sort by due date (earliest first)
                    return date1 < date2
                case (.some, .none):
                    // Only first has due date - it comes first
                    return true
                case (.none, .some):
                    // Only second has due date - it comes first
                    return false
                case (.none, .none):
                    // Neither has due date - sort by created date (newest first)
                    let created1 = item1?.createdAt ?? Date.distantPast
                    let created2 = item2?.createdAt ?? Date.distantPast
                    return created1 > created2
                }
            }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if nonFolderFavorites.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .onAppear {
            syncSettingsFromAppSettings()
            loadFavorites()
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
                    if let issue = favorite.issue {
                        ItemRow(issue: issue, accountColor: getAccountColor(for: issue))
                            .padding(.horizontal, 12)
                    } else if let project = favorite.project {
                        ItemRow(project: project, accountColor: getAccountColor(for: project))
                            .padding(.horizontal, 12)
                    } else if let initiative = favorite.initiative {
                        ItemRow(initiative: initiative, accountColor: getAccountColor(for: initiative))
                            .padding(.horizontal, 12)
                    } else if let customView = favorite.customView {
                        Button(action: {
                            // Construct Linear URL for custom view with organization slug
                            if let orgSlug = getOrganizationSlug() {
                                let url = URL(string: "https://linear.app/\(orgSlug)/view/\(customView.id)")
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }) {
                            genericFavoriteRow(
                                name: customView.name,
                                icon: customView.icon,
                                type: "Custom View",
                                accountColor: AppSettings.shared.accounts.first?.color
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    } else if let cycle = favorite.cycle {
                        Button(action: {
                            // Construct Linear URL for cycle with organization slug
                            if let orgSlug = getOrganizationSlug() {
                                let url = URL(string: "https://linear.app/\(orgSlug)/cycle/\(cycle.id)")
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }) {
                            genericFavoriteRow(
                                name: cycle.name,
                                icon: cycle.icon,
                                type: "Cycle",
                                accountColor: AppSettings.shared.accounts.first?.color
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    } else if let label = favorite.label {
                        Button(action: {
                            // Construct Linear URL for label with organization slug
                            if let orgSlug = getOrganizationSlug() {
                                let url = URL(string: "https://linear.app/\(orgSlug)/label/\(label.id)")
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }) {
                            genericFavoriteRow(
                                name: label.name,
                                icon: label.icon,
                                type: "Label",
                                accountColor: AppSettings.shared.accounts.first?.color
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    // Check if a favorite is just a folder (no actual item)
    private func isFolder(_ favorite: Favorite) -> Bool {
        return favorite.issue == nil &&
               favorite.project == nil &&
               favorite.initiative == nil &&
               favorite.customView == nil &&
               favorite.cycle == nil &&
               favorite.label == nil &&
               favorite.folderName != nil
    }

    // Row for generic favorites (roadmaps, views, etc.)
    private func genericFavoriteRow(name: String, icon: String?, type: String, accountColor: String?) -> some View {
        GenericFavoriteRowView(name: name, icon: icon, type: type, accountColor: accountColor)
    }
}

// MARK: - Generic Favorite Row Component

struct GenericFavoriteRowView: View {
    let name: String
    let icon: String?
    let type: String
    let accountColor: String?

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Left accent color bar (matching ItemRow)
            if let color = accountColor {
                Rectangle()
                    .fill(Color(hex: color))
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Icon
                    if let icon = icon, !icon.isEmpty {
                        if icon.count == 1 {
                            // Emoji
                            Text(icon)
                                .font(.system(size: 14))
                        } else {
                            // Icon name mapped to SF Symbol
                            Image(systemName: mapLinearIconToSFSymbol(icon))
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                        }
                    } else {
                        Image(systemName: iconForType(type))
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                    }

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
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func mapLinearIconToSFSymbol(_ linearIcon: String) -> String {
        switch linearIcon.lowercased() {
        case "users":
            return "person.2.fill"
        case "calendar":
            return "calendar"
        case "inbox":
            return "tray.fill"
        case "archive":
            return "archivebox.fill"
        case "clock":
            return "clock.fill"
        case "star":
            return "star.fill"
        case "heart":
            return "heart.fill"
        case "bookmark":
            return "bookmark.fill"
        case "flag":
            return "flag.fill"
        case "lightning":
            return "bolt.fill"
        case "fire":
            return "flame.fill"
        case "checkmark":
            return "checkmark.circle.fill"
        case "circle":
            return "circle.fill"
        case "square":
            return "square.fill"
        case "target":
            return "target"
        case "folder":
            return "folder.fill"
        case "document":
            return "doc.fill"
        case "paperclip":
            return "paperclip"
        case "link":
            return "link"
        case "chart":
            return "chart.bar.fill"
        case "graph":
            return "chart.line.uptrend.xyaxis"
        case "briefcase":
            return "briefcase.fill"
        case "home":
            return "house.fill"
        case "settings":
            return "gearshape.fill"
        case "bell":
            return "bell.fill"
        case "message":
            return "message.fill"
        case "mail":
            return "envelope.fill"
        case "search":
            return "magnifyingglass"
        case "filter":
            return "line.3.horizontal.decrease.circle.fill"
        case "sort":
            return "arrow.up.arrow.down"
        case "list":
            return "list.bullet"
        case "grid":
            return "square.grid.2x2.fill"
        default:
            return "rectangle.grid.2x2"
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "customview", "view", "custom view":
            return "rectangle.grid.2x2"
        case "cycle":
            return "arrow.triangle.2.circlepath"
        case "label":
            return "tag"
        case "folder":
            return "folder"
        default:
            return "star"
        }
    }
}

// MARK: - FavoritesView Loading/Empty/Error States

extension FavoritesView {
    // MARK: - Loading State

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Loading favorites...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No favorites yet")
                .font(.headline)

            Text("Star items in Linear to see them here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Error State

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error loading favorites")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                loadFavorites()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadFavorites() {
        AppLogger.debug("Loading favorites...", log: AppLogger.ui)
        // Get first enabled account
        guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
              let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            AppLogger.info("No authenticated account found", log: AppLogger.ui)
            errorMessage = "No authenticated account found. Please sign in."
            return
        }

        AppLogger.debug("Found account: \(account.email)", log: AppLogger.ui)
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedFavorites = try await LinearAPI.shared.fetchFavorites(accessToken: accessToken)
                await MainActor.run {
                    AppLogger.info("Loaded \(loadedFavorites.count) favorites", log: AppLogger.ui)
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

    private func getAccountColor(for item: any LinearItem) -> String? {
        // In multi-account setup, you would determine which account owns this item
        // For now, return the first account's color
        return AppSettings.shared.accounts.first?.color
    }

    private func getLinearItem(from favorite: Favorite) -> (any LinearItem)? {
        if let issue = favorite.issue {
            return issue
        } else if let project = favorite.project {
            return project
        } else if let initiative = favorite.initiative {
            return initiative
        }
        return nil
    }

    private func getDueDate(from favorite: Favorite) -> Date? {
        // Use simple DateFormatter for YYYY-MM-DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let issue = favorite.issue, let dueDate = issue.dueDate {
            return formatter.date(from: dueDate)
        } else if let project = favorite.project, let targetDate = project.targetDate {
            return formatter.date(from: targetDate)
        } else if let initiative = favorite.initiative, let targetDate = initiative.targetDate {
            return formatter.date(from: targetDate)
        }

        return nil
    }

    private func getOrganizationSlug() -> String? {
        // Get the organization slug from the first enabled account
        return AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid })?.organizationSlug
    }
}
