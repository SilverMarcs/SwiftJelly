//
//  TabSelection.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 24/08/2025.
//

import Foundation

// Enum for tab cases
enum TabSelection: String, CaseIterable {
    case home = "home"
    case libraries = "libraries"
    case local = "local"
    case settings = "settings"
    case search = "search"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .libraries: return "Libraries"
        case .local: return "Local"
        case .settings: return "Settings"
        case .search: return "Search"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .libraries: return "film"
        case .local: return "folder"
        case .settings: return "gear"
        case .search: return "magnifyingglass"
        }
    }
    
    var shortcutKey: String? {
        switch self {
        case .home: return "1"
        case .libraries: return "2"
        case .local: return "3"
        case .settings: return ","
        case .search: return "f"
        }
    }
}
