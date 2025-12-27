//
//  ViewOptions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 27.12.25.
//

import SwiftUI

enum TVNavigationStyle: String, CaseIterable {
    case sidebar
    case tabBar
    
    var title: String {
        switch self {
        case .sidebar: "Sidebar"
        case .tabBar: "Top Tab Bar"
        }
    }
}

enum EpisodeNamingStyle: String, CaseIterable {
    case compact
    case detailed
    
    var title: String {
        switch self {
        case .compact: "S2E13"
        case .detailed: "S2, E13"
        }
    }
}

extension CaseIterable where Self: Equatable {
    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let nextIdx = all.index(after: idx)
        return all[nextIdx == all.endIndex ? all.startIndex : nextIdx]
    }
}

extension View {
    @ViewBuilder
    func tvNavigationStyle(_ style: TVNavigationStyle) -> some View {
        #if os(tvOS)
        switch style {
        case .sidebar:
            self.tabViewStyle(.sidebarAdaptable)
        case .tabBar:
            self.tabViewStyle(.tabBarOnly)
        }
        #else
        self
        #endif
    }
}
