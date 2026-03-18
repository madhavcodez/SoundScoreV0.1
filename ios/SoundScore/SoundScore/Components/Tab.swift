import SwiftUI

enum Tab: String, CaseIterable {
    case feed
    case log
    case search
    case aiBuddy
    case profile

    var label: String {
        switch self {
        case .feed: "Feed"
        case .log: "Diary"
        case .search: "Discover"
        case .aiBuddy: "Cadence"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .feed: "rectangle.stack"
        case .log: "book"
        case .search: "magnifyingglass"
        case .aiBuddy: "sparkles"
        case .profile: "person.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .feed: "rectangle.stack.fill"
        case .log: "book.fill"
        case .search: "magnifyingglass"
        case .aiBuddy: "sparkles"
        case .profile: "person.circle.fill"
        }
    }
}
