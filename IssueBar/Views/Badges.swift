import SwiftUI

struct DueDateBadge: View {
    let dueDate: String
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isOverdue ? "calendar.badge.exclamationmark" : "calendar")
                .font(.system(size: 9))
                .foregroundColor(isOverdue ? .red : .secondary)

            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundColor(isOverdue ? .red : .secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
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

    var body: some View {
        HStack(spacing: 3) {
            if let icon = project.icon, !icon.isEmpty, icon.count == 1 {
                Text(icon)
                    .font(.system(size: 9))
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Text(project.name)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}

struct LabelBadge: View {
    let label: IssueLabel

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: label.color))
                .frame(width: 6, height: 6)

            Text(label.name)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}
