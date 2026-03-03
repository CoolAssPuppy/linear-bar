import SwiftUI

/// Centralized design tokens for IssueBar.
/// All spacing, color, and typography constants live here.
enum AppStyle {

    // MARK: - Spacing

    enum Spacing {
        /// 4pt -- tight spacing between inline elements
        static let xxs: CGFloat = 4
        /// 6pt -- badge internal padding, small gaps
        static let xs: CGFloat = 6
        /// 8pt -- standard inter-element spacing
        static let sm: CGFloat = 8
        /// 12pt -- list item horizontal padding, content spacing
        static let md: CGFloat = 12
        /// 16pt -- section/container horizontal padding
        static let lg: CGFloat = 16
        /// 20pt -- form/page padding
        static let xl: CGFloat = 20
        /// 24pt -- large content gaps
        static let xxl: CGFloat = 24
    }

    // MARK: - Colors (semantic system colors)

    enum Colors {
        static let windowBackground = Color(nsColor: .windowBackgroundColor)
        static let controlBackground = Color(nsColor: .controlBackgroundColor)
        static let hoverHighlight = Color(nsColor: .selectedContentBackgroundColor).opacity(0.3)
        static let subtleSeparator = Color(nsColor: .separatorColor)
    }

    // MARK: - Typography

    enum Font {
        static let rowTitle = SwiftUI.Font.system(size: 13, weight: .medium)
        static let rowSubtitle = SwiftUI.Font.system(size: 12)
        static let rowCaption = SwiftUI.Font.system(size: 11)
        static let badge = SwiftUI.Font.system(size: 10)
        static let sectionHeader = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let headerTitle = SwiftUI.Font.system(size: 15, weight: .bold, design: .rounded)
    }

    // MARK: - Layout

    enum Layout {
        static let popoverWidth: CGFloat = 400
        static let popoverHeight: CGFloat = 500
        static let settingsWidth: CGFloat = 500
        static let settingsHeight: CGFloat = 600
        static let tabBarHeight: CGFloat = 44
        static let badgeCornerRadius: CGFloat = 4
        static let rowCornerRadius: CGFloat = 6
        static let accountIndicatorWidth: CGFloat = 3
    }
}
