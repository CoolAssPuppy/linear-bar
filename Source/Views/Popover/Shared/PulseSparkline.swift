import SwiftUI

/// Day-by-day stacked bar chart for the Pulse tab. Each bar represents one
/// day; the segments stack issue / project / initiative activity within
/// that day. The legend underneath maps each color to its category. The
/// sparkline this replaces collapsed all three streams into one peak,
/// hiding which kind of work was driving activity on a given day.
struct PulseSparkline: View {
    /// Per-day, per-category bucket counts. Oldest day first.
    let buckets: [PulseDayBuckets]

    @Environment(\.theme) private var theme

    private static let chartHeight: CGFloat = 64
    private static let barCornerRadius: CGFloat = 1.5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            chart
            legend
        }
    }

    private var chart: some View {
        GeometryReader { geo in
            let peak = max(buckets.map { $0.total }.max() ?? 0, 1)
            let count = max(buckets.count, 1)
            // Bars share the row evenly with a 2px-min gap so consecutive
            // days don't visually merge into a single column.
            let gap: CGFloat = 2
            let barWidth = max((geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count), 2)

            HStack(alignment: .bottom, spacing: gap) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                    bar(for: bucket, peak: peak, height: geo.size.height, width: barWidth)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: Self.chartHeight)
    }

    private var colors: PulseChartColors { PulseChartColors.forTheme(isDark: theme.isDark) }

    /// Stacks issue → project → initiative bottom-up so the densest
    /// category (issues) anchors the bar and lighter activity layers
    /// read on top.
    private func bar(for bucket: PulseDayBuckets, peak: Int, height: CGFloat, width: CGFloat) -> some View {
        let scale = height / CGFloat(peak)
        let issueHeight = CGFloat(bucket.issues) * scale
        let projectHeight = CGFloat(bucket.projects) * scale
        let initiativeHeight = CGFloat(bucket.initiatives) * scale

        return VStack(spacing: 0) {
            segment(height: initiativeHeight, color: colors.initiatives, width: width, isTop: true)
            segment(height: projectHeight, color: colors.projects, width: width, isTop: initiativeHeight == 0)
            segment(height: issueHeight, color: colors.issues, width: width, isTop: initiativeHeight + projectHeight == 0)

            // Empty days still show a faint baseline tick so the X axis
            // reads as continuous time rather than missing days.
            if bucket.total == 0 {
                Rectangle()
                    .fill(theme.dim.opacity(0.35))
                    .frame(width: width, height: 1.5)
            }
        }
        .frame(width: width, alignment: .bottom)
    }

    @ViewBuilder
    private func segment(height: CGFloat, color: Color, width: CGFloat, isTop: Bool) -> some View {
        if height > 0 {
            UnevenRoundedRectangle(
                topLeadingRadius: isTop ? Self.barCornerRadius : 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: isTop ? Self.barCornerRadius : 0,
                style: .continuous
            )
            .fill(color)
            .frame(width: width, height: height)
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: colors.issues, label: "Issues")
            legendItem(color: colors.projects, label: "Projects")
            legendItem(color: colors.initiatives, label: "Initiatives")
            Spacer(minLength: 0)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }
}

/// Categorical chart palette for the Pulse stacked bars. Independent of
/// the theme accent so issues / projects / initiatives stay visually
/// distinct regardless of which palette is active. Tuned per mode:
/// saturated mid-tones on light, brighter tints on dark, so each
/// category pops against any of the configured backgrounds.
private struct PulseChartColors {
    let issues: Color
    let projects: Color
    let initiatives: Color

    static let light = PulseChartColors(
        issues:      Color(red: 0x25/255, green: 0x63/255, blue: 0xEB/255),
        projects:    Color(red: 0xEA/255, green: 0x58/255, blue: 0x0C/255),
        initiatives: Color(red: 0x05/255, green: 0x96/255, blue: 0x69/255)
    )

    static let dark = PulseChartColors(
        issues:      Color(red: 0x60/255, green: 0xA5/255, blue: 0xFA/255),
        projects:    Color(red: 0xFB/255, green: 0x92/255, blue: 0x3C/255),
        initiatives: Color(red: 0x34/255, green: 0xD3/255, blue: 0x99/255)
    )

    static func forTheme(isDark: Bool) -> PulseChartColors {
        isDark ? .dark : .light
    }
}

/// One day's activity counts split by category. Keeps the stacking order
/// (issues bottom, initiatives top) consistent across renders.
struct PulseDayBuckets: Hashable {
    let issues: Int
    let projects: Int
    let initiatives: Int

    var total: Int { issues + projects + initiatives }

    static let empty = PulseDayBuckets(issues: 0, projects: 0, initiatives: 0)
}

// MARK: - Bucketer

enum PulseBucketer {
    /// Produces `dayCount` buckets ending today (inclusive), with each
    /// day's `LinearPulseUpdate`s split into issues / projects /
    /// initiatives. Linear's pulse feed today only carries project +
    /// initiative status updates — the `issues` lane is reserved for
    /// when issue activity is folded into pulse and stays at zero
    /// until then. The chart still renders the lane so the legend
    /// reads as a fixed contract.
    static func buckets(
        updates: [LinearPulseUpdate],
        dayCount: Int,
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> [PulseDayBuckets] {
        let startOfToday = calendar.startOfDay(for: reference)
        let days: [Date] = (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: startOfToday)
        }.reversed()

        struct Counts { var projects = 0; var initiatives = 0 }
        var perDay: [Date: Counts] = [:]

        for update in updates {
            guard let createdAt = update.createdAt else { continue }
            let day = calendar.startOfDay(for: createdAt)
            var counts = perDay[day] ?? Counts()
            if update.project != nil {
                counts.projects += 1
            } else if update.initiative != nil {
                counts.initiatives += 1
            }
            perDay[day] = counts
        }

        return days.map { day in
            let counts = perDay[day] ?? Counts()
            return PulseDayBuckets(
                issues: 0,
                projects: counts.projects,
                initiatives: counts.initiatives
            )
        }
    }
}
