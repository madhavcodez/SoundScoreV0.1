import SwiftUI

enum Tab: String, CaseIterable {
    case feed
    case log
    case search
    case lists
    case profile

    var label: String {
        switch self {
        case .feed: "Feed"
        case .log: "Diary"
        case .search: "Discover"
        case .lists: "Lists"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .feed: "rectangle.stack"
        case .log: "book"
        case .search: "magnifyingglass"
        case .lists: "list.bullet.rectangle"
        case .profile: "person.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .feed: "rectangle.stack.fill"
        case .log: "book.fill"
        case .search: "magnifyingglass"
        case .lists: "list.bullet.rectangle.fill"
        case .profile: "person.circle.fill"
        }
    }
}
