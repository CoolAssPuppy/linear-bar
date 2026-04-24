import SwiftUI

/// Kept for API stability at call sites. Delegates to the shared
/// StatePlaceholderView.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        StatePlaceholderView(systemImage: icon, title: title, subtitle: subtitle)
    }
}
