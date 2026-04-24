import SwiftUI

/// Thin EKG-style line chart for the Pulse tab. Draws one point per
/// day across the Pulse window (14 days today) with a line through
/// them and a soft gradient fill underneath. Intentionally dense and
/// minimal — meant to read as a single pulse of workspace activity,
/// not a full chart.
struct PulseSparkline: View {
    /// One count per day, oldest first. The array length determines
    /// the X resolution of the line (7, 14, 30, 90, etc.) — the chart
    /// scales its step width accordingly.
    let buckets: [Int]

    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { geo in
            let peak = CGFloat(max(buckets.max() ?? 0, 1))
            let stepX = geo.size.width / CGFloat(max(buckets.count - 1, 1))
            let points = buckets.enumerated().map { index, value in
                CGPoint(
                    x: CGFloat(index) * stepX,
                    y: geo.size.height - (geo.size.height * CGFloat(value) / peak)
                )
            }

            ZStack {
                fillPath(points: points, height: geo.size.height)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.24), theme.primary.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                strokePath(points: points)
                    .stroke(
                        theme.primary,
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(height: 36)
    }

    private func fillPath(points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    private func strokePath(points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }
}

// MARK: - Bucketer

enum PulseBucketer {
    /// Produces `dayCount` buckets ending today (inclusive), counting
    /// how many updates fell on each day by `createdAt`. Missing days
    /// render as zero. Caller passes the same day count that was used
    /// to scope the Pulse query so the chart's X axis matches what's
    /// in `updates`.
    static func buckets(
        updates: [LinearPulseUpdate],
        dayCount: Int,
        calendar: Calendar = .current,
        reference: Date = Date()
    ) -> [Int] {
        let startOfToday = calendar.startOfDay(for: reference)
        let days: [Date] = (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: startOfToday)
        }.reversed()

        var counts: [Date: Int] = [:]
        for update in updates {
            guard let createdAt = update.createdAt else { continue }
            counts[calendar.startOfDay(for: createdAt), default: 0] += 1
        }

        return days.map { counts[$0] ?? 0 }
    }
}
