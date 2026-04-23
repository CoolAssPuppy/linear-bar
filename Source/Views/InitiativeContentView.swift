import SwiftUI

struct InitiativeContentView: View {
    let initiative: Initiative

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(initiative.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)

            if let description = initiative.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.muted)
                    .lineLimit(2)
            }

            if let targetDate = initiative.targetDate {
                HStack(spacing: 6) {
                    DueDateBadge(dueDate: targetDate, isOverdue: initiative.isOverdue)
                }
            }

            if let progress = initiative.progress {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.muted)
            }
        }
    }
}
