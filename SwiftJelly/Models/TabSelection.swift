//
//  TabSelection.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import SwiftUI
import JellyfinAPI

// Enum for tab cases
enum TabSelection: String, CaseIterable {
    case home = "home"
    case favorites = "favourites"
    case movies = "movies"
    case shows = "shows"
    case libraries = "libraries"
    case settings = "settings"
    case search = "search"
    
    static let compactTabs: [TabSelection] = [.search, .home, .favorites, .movies, .shows]
    
    static let extendedTabs: [TabSelection] = [.search, .home, .favorites, .settings]
    static let extendedlibraryTabs: [TabSelection] = [.movies, .shows, .libraries]

    var title: String {
        switch self {
        case .home: return "Home"
        case .favorites: return "Favorites"
        case .settings: return "Settings"
        case .search: return "Search"
        case .shows: return "Shows"
        case .movies: return "Movies"
        case .libraries: return "Libraries"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .favorites: return "star"
        case .settings: return "gear"
        case .search: return "magnifyingglass"
        case .shows: return "tv"
        case .movies: return "movieclapper.fill"
        case .libraries: return "building.columns"
        }
    }
    
    var shortcutKey: String? {
        switch self {
        case .home: return "1"
        case .favorites: return "2"
        case .settings: return ","
        case .search: return "f"
        case .shows: return "s"
        case .movies: return "m"
        case .libraries: return "3"
        }
    }
    
    @ViewBuilder
    var tabView: some View {
        switch self {
        case .home: HomeView()
        case .favorites: FilteredMediaView(filter: .favorites)
        case .shows: FilteredMediaView(filter: .library(BaseItemDto(collectionType: .tvshows, name: "TV Shows")))
        case .movies: FilteredMediaView(filter: .library(BaseItemDto(collectionType: .movies, name: "Movies")))
        case .libraries: LibraryView()
        case .settings: SettingsView()
        case .search: SearchView()
        }
    }
}
