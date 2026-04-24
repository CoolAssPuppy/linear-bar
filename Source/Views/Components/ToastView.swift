import SwiftUI

/// Bottom-right toast surface. Observes `ToastCenter.shared` and renders
/// the active message on the primary-theme color; dismisses automatically
/// when the center clears.
///
/// Placed as an overlay on the popover root so it floats above whichever
/// tab happens to be visible and can't shift layout.
struct ToastOverlay: View {
    @ObservedObject private var toasts = ToastCenter.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                if let text = toasts.message {
                    toastPill(text: text)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity
                        ))
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                }
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.18), value: toasts.message)
    }

    private func toastPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.primaryForeground)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.primary)
                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
            )
    }
}
