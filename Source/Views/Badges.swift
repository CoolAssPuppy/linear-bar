import SwiftUI

struct DueDateBadge: View {
    let dueDate: String
    let isOverdue: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isOverdue ? "calendar.badge.exclamationmark" : "calendar")
                .font(.system(size: 9))
                .foregroundStyle(isOverdue ? theme.destructive : theme.muted)

            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundStyle(isOverdue ? theme.destructive : theme.muted)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                .fill(isOverdue ? theme.destructive.opacity(0.12) : theme.cardInset)
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dueDate) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return dueDate
    }
}

struct ProjectBadge: View {
    let project: ProjectReference

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            if let icon = project.icon, !icon.isEmpty, icon.count == 1 {
                Text(icon)
                    .font(.system(size: 9))
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 9))
                    .foregroundStyle(theme.muted)
            }

            Text(project.name)
                .font(.system(size: 10))
                .foregroundStyle(theme.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                .fill(theme.cardInset)
        )
    }
}

struct LabelBadge: View {
    let label: IssueLabel

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: label.color))
                .frame(width: 6, height: 6)

            Text(label.name)
                .font(.system(size: 10))
                .foregroundStyle(theme.muted)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                .fill(theme.cardInset)
        )
    }
}
