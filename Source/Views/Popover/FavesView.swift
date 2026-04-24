import SwiftUI

/// Faves tab. Pulls the viewer's starred items from Linear's
/// `viewer.favorites` connection and lists them in popover-density rows.
/// Renders issue and project favorites today; other Favorite subtypes
/// (document, cycle, custom view, label, roadmap) decode with nil
/// targets and are filtered out.
struct FavesView: View {
    @State private var favorites: [LinearFavorite] = []
    @State private var filtered: [LinearFavorite] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            subHeader

            Group {
                if isLoading && filtered.isEmpty {
                    LoadingStateView("Loading favorites…")
                } else if AppSettings.shared.accounts.isEmpty {
                    NoAccountView(message: "Connect your Linear account to see your favorites.")
                } else if let error = errorMessage {
                    ErrorStateView(title: "Could not load favorites", message: error, onRetry: loadData)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "star",
                        title: "No favorites yet",
                        subtitle: "Star issues and projects in Linear and they'll show up here."
                    )
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                hasLoadedOnce = true
                loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .teamFilterChanged)) { _ in
            rebuildFiltered()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            loadData()
        }
    }

    // MARK: - Sub-header

    private var subHeader: some View {
        HStack(spacing: 8) {
            PopoverTeamChip()
            Spacer(minLength: 0)
            Text(countLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var countLabel: String {
        let count = filtered.count
        if count == 0 { return "No favorites" }
        if count == 1 { return "1 favorite" }
        return "\(count) favorites"
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { favorite in
                    FavoriteRow(favorite: favorite)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Data

    private func loadData() {
        let session: PopoverSession
        do {
            session = try PopoverSession.resolve()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await LinearAPI.shared.fetchFavorites(
                    accessToken: session.accessToken,
                    accountEmail: session.accountEmail
                )

                await MainActor.run {
                    favorites = fetched
                    rebuildFiltered()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func rebuildFiltered() {
        let selectedTeam = AppSettings.shared.selectedTeamId

        // Drop favorites whose subtype we don't render yet (issue, project,
        // customView). Folders, cycles, documents, labels, roadmaps, etc.
        // come back with all three targets nil and get skipped.
        let renderable = favorites.filter {
            $0.issue != nil || $0.project != nil || $0.customView != nil
        }

        let scoped: [LinearFavorite]
        if let selectedTeam {
            // Issues filter by team; projects and custom views pass through
            // (no team info in our current selection for either).
            scoped = renderable.filter { fav in
                guard let teamId = fav.issue?.team?.id else { return true }
                return teamId == selectedTeam
            }
        } else {
            scoped = renderable
        }

        filtered = scoped
    }
}

// MARK: - Row

private struct FavoriteRow: View {
    let favorite: LinearFavorite

    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 10) {
                leadingGlyph
                    .frame(width: 14, alignment: .center)

                if let issue = favorite.issue {
                    IssueIdentifierLabel(identifier: issue.identifier, url: issue.url)
                } else if let project = favorite.project {
                    IssueIdentifierLabel(identifier: "PROJ", url: project.url)
                } else if favorite.customView != nil {
                    IssueIdentifierLabel(identifier: "VIEW", url: customViewURL)
                } else {
                    IssueIdentifierLabel(identifier: "FAV", url: nil)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let folder = favorite.folderName, !folder.isEmpty {
                    Text(folder)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.muted)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Rectangle().fill(isHovered ? theme.cardInset : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var leadingGlyph: some View {
        if let issue = favorite.issue {
            IssueStateCircle(state: issue.state)
        } else if let project = favorite.project {
            ProjectGlyph(color: project.color)
        } else if let view = favorite.customView {
            ProjectGlyph(color: view.color)
        } else {
            IssueStateCircle(state: nil)
        }
    }

    private var title: String {
        favorite.issue?.title
            ?? favorite.project?.name
            ?? favorite.customView?.name
            ?? ""
    }

    private var url: String? {
        favorite.issue?.url
            ?? favorite.project?.url
            ?? customViewURL
    }

    /// Linear's CustomView type doesn't expose a URL field; synthesize
    /// one from the workspace slug + view id. Returns nil when we don't
    /// have a workspace slug on hand (e.g. demo mode with stub data).
    private var customViewURL: String? {
        guard let view = favorite.customView,
              let slug = AppSettings.shared.primaryValidAccount?.organizationSlug,
              !slug.isEmpty else {
            return nil
        }
        return "https://linear.app/\(slug)/view/\(view.id)"
    }

    private func openInLinear() {
        guard let url else { return }
        _ = SafeExternalURL.openLinearURL(from: url)
    }
}
