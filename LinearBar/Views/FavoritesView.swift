import SwiftUI

/// View displaying user's favorite items from Linear
struct FavoritesView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var favorites: [Favorite] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var nonFolderFavorites: [Favorite] {
        favorites.filter { favorite in
            // Filter out folders
            guard !isFolder(favorite) else { return false }

            // Apply state filters for issues
            if let issue = favorite.issue {
                if let stateType = issue.state?.type {
                    if stateType == "completed" && !settings.showCompletedItems {
                        return false
                    }
                    if stateType == "canceled" && !settings.showCanceledItems {
                        return false
                    }
                }
            }

            // Apply state filters for projects
            if let project = favorite.project {
                if project.state.lowercased() == "completed" && !settings.showCompletedItems {
                    return false
                }
                if project.state.lowercased() == "canceled" && !settings.showCanceledItems {
                    return false
                }
            }

            // Apply state filters for initiatives
            if let initiative = favorite.initiative {
                if initiative.status?.lowercased() == "completed" && !settings.showCompletedItems {
                    return false
                }
            }

            return true
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
            loadFavorites()
        }
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
                            // Construct Linear URL for custom view
                            let url = URL(string: "https://linear.app/view/\(customView.id)")
                            if let url = url {
                                NSWorkspace.shared.open(url)
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
                            // Construct Linear URL for cycle
                            let url = URL(string: "https://linear.app/cycle/\(cycle.id)")
                            if let url = url {
                                NSWorkspace.shared.open(url)
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
                            // Construct Linear URL for label
                            let url = URL(string: "https://linear.app/label/\(label.id)")
                            if let url = url {
                                NSWorkspace.shared.open(url)
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
        print("[FavoritesView] Loading favorites...")
        // Get first enabled account
        guard let account = AppSettings.shared.accounts.first(where: { $0.isEnabled && $0.authStatus == .valid }),
              let accessToken = KeychainService.shared.retrieveAccessToken(forAccount: account.email) else {
            print("[FavoritesView] No authenticated account found")
            errorMessage = "No authenticated account found. Please sign in."
            return
        }

        print("[FavoritesView] Found account: \(account.email)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedFavorites = try await LinearAPI.shared.fetchFavorites(accessToken: accessToken)
                await MainActor.run {
                    print("[FavoritesView] Loaded \(loadedFavorites.count) favorites")
                    self.favorites = loadedFavorites
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("[FavoritesView] Error loading favorites: \(error)")
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
}
