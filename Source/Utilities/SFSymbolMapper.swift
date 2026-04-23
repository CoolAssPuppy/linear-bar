import Foundation

/// Maps Linear icon names to SF Symbols
enum SFSymbolMapper {

    /// Maps a Linear icon name to its corresponding SF Symbol
    /// - Parameter linearIcon: The Linear icon name (e.g., "users", "calendar")
    /// - Returns: The SF Symbol name to use
    static func sfSymbol(for linearIcon: String) -> String {
        switch linearIcon.lowercased() {
        case "users":
            return "person.2.fill"
        case "calendar":
            return "calendar"
        case "inbox":
            return "tray.fill"
        case "archive":
            return "archivebox.fill"
        case "clock":
            return "clock.fill"
        case "star":
            return "star.fill"
        case "heart":
            return "heart.fill"
        case "bookmark":
            return "bookmark.fill"
        case "flag":
            return "flag.fill"
        case "lightning":
            return "bolt.fill"
        case "fire":
            return "flame.fill"
        case "checkmark":
            return "checkmark.circle.fill"
        case "circle":
            return "circle.fill"
        case "square":
            return "square.fill"
        case "target":
            return "target"
        case "folder":
            return "folder.fill"
        case "document":
            return "doc.fill"
        case "paperclip":
            return "paperclip"
        case "link":
            return "link"
        case "chart":
            return "chart.bar.fill"
        case "graph":
            return "chart.line.uptrend.xyaxis"
        case "briefcase":
            return "briefcase.fill"
        case "home":
            return "house.fill"
        case "settings":
            return "gearshape.fill"
        case "bell":
            return "bell.fill"
        case "message":
            return "message.fill"
        case "mail":
            return "envelope.fill"
        case "search":
            return "magnifyingglass"
        case "filter":
            return "line.3.horizontal.decrease.circle.fill"
        case "sort":
            return "arrow.up.arrow.down"
        case "list":
            return "list.bullet"
        case "grid":
            return "square.grid.2x2.fill"
        case "rocket":
            return "rocket.fill"
        case "trophy":
            return "trophy.fill"
        case "lightbulb":
            return "lightbulb.fill"
        default:
            return "circle.fill"
        }
    }

    /// Returns the SF Symbol for a favorite item type
    /// - Parameter type: The type of favorite (e.g., "customView", "cycle", "label")
    /// - Returns: The SF Symbol name to use
    static func sfSymbolForFavoriteType(_ type: String) -> String {
        switch type.lowercased() {
        case "customview", "view", "custom view":
            return "rectangle.grid.2x2"
        case "cycle":
            return "arrow.triangle.2.circlepath"
        case "label":
            return "tag"
        case "folder":
            return "folder"
        default:
            return "star"
        }
    }
}
