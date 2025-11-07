//
//  TabSelection.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import SwiftUI

// Enum for tab cases
enum TabSelection: String, CaseIterable {
    case home = "home"
    case favorites = "favourites"
    case libraries = "libraries"
    case settings = "settings"
    case search = "search"
    
    #if os(macOS)
    static let allCases: [TabSelection] = [.home, .favorites, .libraries, .settings, .search]
    #else
    static let allCases: [TabSelection] = [.home, .favorites, .libraries, .search]
    #endif
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .favorites: return "Favorites"
        case .libraries: return "Libraries"
        case .settings: return "Settings"
        case .search: return "Search"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .favorites: return "star"
        case .libraries: return "film"
        case .settings: return "gear"
        case .search: return "magnifyingglass"
        }
    }
    
    var shortcutKey: String? {
        switch self {
        case .home: return "1"
        case .favorites: return "2"
        case .libraries: return "3"
        case .settings: return ","
        case .search: return "f"
        }
    }
    
    @ViewBuilder
    var tabView: some View {
        switch self {
        case .home: HomeView()
        case .favorites: FavoritesView()
        case .libraries: LibraryView()
        case .settings: SettingsView()
        case .search: EmptyView()
        }
    }
}
