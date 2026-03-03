import SwiftUI

/// Reusable row component for displaying Linear items (issues, projects, initiatives)
struct ItemRow: View {
    let issue: Issue?
    let project: Project?
    let initiative: Initiative?
    let accountColor: String?

    @State private var isHovered = false

    init(issue: Issue, accountColor: String? = nil) {
        self.issue = issue
        self.project = nil
        self.initiative = nil
        self.accountColor = accountColor
    }

    init(project: Project, accountColor: String? = nil) {
        self.issue = nil
        self.project = project
        self.initiative = nil
        self.accountColor = accountColor
    }

    init(initiative: Initiative, accountColor: String? = nil) {
        self.issue = nil
        self.project = nil
        self.initiative = initiative
        self.accountColor = accountColor
    }

    var body: some View {
        Button(action: openInLinear) {
            HStack(spacing: 12) {
                if let color = accountColor {
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        typeIcon

                        if let issue = issue {
                            IssueContentView(issue: issue)
                        } else if let project = project {
                            ProjectContentView(project: project)
                        } else if let initiative = initiative {
                            InitiativeContentView(initiative: initiative)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? AppStyle.Colors.hoverHighlight : Color.clear)
        .cornerRadius(AppStyle.Layout.rowCornerRadius)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Type Icon

    private var typeIcon: some View {
        Group {
            if let issue = issue {
                IssueStatusIcon(issue: issue)
            } else if let project = project {
                ProjectStatusIcon(project: project)
            } else if let initiative = initiative {
                InitiativeStatusIcon(initiative: initiative)
            }
        }
        .font(.system(size: 16))
    }

    // MARK: - Actions

    private func openInLinear() {
        let urlString = issue?.url ?? project?.url ?? initiative?.url
        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
