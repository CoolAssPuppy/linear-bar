import SwiftUI

/// 14-day activity bar chart. One stacked bar per day showing how many
/// issues, projects, and initiatives were edited that day, colored by type.
/// Used at the top of Pulse; designed to read cleanly at 380pt wide.
struct ActivitySpark: View {
    let buckets: [DayBucket]

    @Environment(\.theme) private var theme

    /// Visible window. Caller must pass exactly `dayCount` buckets,
    /// oldest first. The view doesn't re-bucket — pass pre-aggregated data.
    static let dayCount = 14

    struct DayBucket: Identifiable {
        let day: Date
        let issues: Int
        let projects: Int
        let initiatives: Int

        var id: Date { day }
        var total: Int { issues + projects + initiatives }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            chart
            legend
        }
        .padding(14)
        .appSurface(radius: AppRadius.lg, fill: theme.card, border: theme.border)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("ACTIVITY")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(theme.tertiary)
            Spacer(minLength: 0)
            Text("\(total) edits · last \(Self.dayCount) days")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }

    private var total: Int {
        buckets.reduce(0) { $0 + $1.total }
    }

    // MARK: - Chart

    /// Per-day stacked bars. Heights scale against the busiest day's total so
    /// a quiet stretch still shows proportions instead of flat zeros.
    private var chart: some View {
        let peak = max(buckets.map(\.total).max() ?? 0, 1)

        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(buckets) { bucket in
                bar(for: bucket, peak: peak)
            }
        }
        .frame(height: 48)
    }

    private func bar(for bucket: DayBucket, peak: Int) -> some View {
        let totalFraction = CGFloat(bucket.total) / CGFloat(peak)
        let barFill: [(Color, Int)] = [
            (theme.primary, bucket.issues),
            (theme.warning, bucket.projects),
            (Color(hex: "#BB6BD9"), bucket.initiatives)
        ]

        return GeometryReader { proxy in
            let barHeight = max(proxy.size.height * totalFraction, bucket.total > 0 ? 2 : 0)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    ForEach(Array(barFill.enumerated()), id: \.offset) { _, segment in
                        if segment.1 > 0 {
                            Rectangle()
                                .fill(segment.0)
                                .frame(height: barHeight * CGFloat(segment.1) / CGFloat(max(bucket.total, 1)))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(emptyTick(visible: bucket.total == 0))
            }
        }
    }

    private func emptyTick(visible: Bool) -> some View {
        // Faint dot for zero-activity days so the axis still reads as a
        // 14-day window rather than disappearing entirely on quiet stretches.
        Rectangle()
            .fill(theme.divider)
            .frame(height: 1)
            .opacity(visible ? 1 : 0)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 12) {
            legendDot(color: theme.primary, label: "Issues")
            legendDot(color: theme.warning, label: "Projects")
            legendDot(color: Color(hex: "#BB6BD9"), label: "Initiatives")
            Spacer(minLength: 0)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }
}

// MARK: - Bucketer

enum ActivityBucketer {
    /// Produces `ActivitySpark.dayCount` buckets ending today (inclusive),
    /// counting items by updatedAt. Missing dates render as empty bars.
    static func buckets(
        issues: [Issue],
        projects: [Project],
        initiatives: [Initiative],
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> [ActivitySpark.DayBucket] {
        let startOfToday = calendar.startOfDay(for: reference)
        let days = (0..<ActivitySpark.dayCount).compactMap {
            calendar.date(byAdding: .day, value: -($0), to: startOfToday)
        }.reversed()

        func dayKey(_ date: Date?) -> Date? {
            guard let date else { return nil }
            return calendar.startOfDay(for: date)
        }

        var issueCounts: [Date: Int] = [:]
        for issue in issues {
            if let key = dayKey(issue.updatedAt) { issueCounts[key, default: 0] += 1 }
        }
        var projectCounts: [Date: Int] = [:]
        for project in projects {
            if let key = dayKey(project.updatedAt) { projectCounts[key, default: 0] += 1 }
        }
        var initiativeCounts: [Date: Int] = [:]
        for initiative in initiatives {
            if let key = dayKey(initiative.updatedAt) { initiativeCounts[key, default: 0] += 1 }
        }

        return days.map { day in
            ActivitySpark.DayBucket(
                day: day,
                issues: issueCounts[day] ?? 0,
                projects: projectCounts[day] ?? 0,
                initiatives: initiativeCounts[day] ?? 0
            )
        }
    }
}
