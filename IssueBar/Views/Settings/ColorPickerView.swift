import SwiftUI

/// View for selecting an account color
struct ColorPickerView: View {
    let account: LinearAccount
    @Binding var isPresented: Bool
    @State private var hexInput: String = ""
    @State private var showInvalidHexError: Bool = false

    private let availableColors: [String] = [
        "#5E6AD2", // Linear purple
        "#10B981", // green
        "#F59E0B", // orange
        "#EF4444", // red
        "#3B82F6", // blue
        "#000000", // black
        "#EC4899", // pink
        "#8B4513"  // brown
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Account Color")
                .font(.headline)
                .padding(.top, 8)

            colorGrid

            Divider()
                .padding(.horizontal, 16)

            customHexInput

            Button("Cancel") {
                closeWindow()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 8)
        }
        .frame(width: 340, height: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Color Grid

    private var colorGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach(availableColors.prefix(4), id: \.self) { colorHex in
                    colorButton(colorHex)
                }
            }

            HStack(spacing: 16) {
                ForEach(availableColors.suffix(4), id: \.self) { colorHex in
                    colorButton(colorHex)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func colorButton(_ colorHex: String) -> some View {
        Button(action: {
            AppSettings.shared.setAccountColor(colorHex, forAccount: account.email)
            closeWindow()
        }) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(account.color == colorHex ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Hex Input

    private var customHexInput: some View {
        VStack(spacing: 8) {
            Text("Or enter a hex code:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                TextField("#5E6AD2", text: $hexInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 140)
                    .onSubmit {
                        applyCustomHex()
                    }

                Button("Apply") {
                    applyCustomHex()
                }
                .buttonStyle(.borderedProminent)
            }

            if showInvalidHexError {
                Text("Invalid hex code")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    private func applyCustomHex() {
        var cleanedHex = hexInput.trimmingCharacters(in: .whitespaces).uppercased()

        if !cleanedHex.hasPrefix("#") {
            cleanedHex = "#" + cleanedHex
        }

        let hexPattern = "^#[0-9A-F]{6}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: cleanedHex.utf16.count)

        if regex?.firstMatch(in: cleanedHex, range: range) != nil {
            AppSettings.shared.setAccountColor(cleanedHex, forAccount: account.email)
            showInvalidHexError = false
            closeWindow()
        } else {
            showInvalidHexError = true
        }
    }

    private func closeWindow() {
        isPresented = false
        NSApplication.shared.keyWindow?.close()
    }
}
