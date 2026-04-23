import SwiftUI

/// Placeholder while the simplified Mine tab lands. Real implementation
/// will render `viewer.assignedIssues` with a flat list and a sort picker.
struct MyIssuesView: View {
    var body: some View {
        EmptyStateView(icon: "checkmark.circle", title: "Mine", subtitle: "Coming in the next milestone.")
    }
}
