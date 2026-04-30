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

enum ContinueWatchingStyle: String, CaseIterable {
    case combined
    case separated

    var title: String {
        switch self {
        case .combined: "Combined"
        case .separated: "Separated"
        }
    }
}

enum MaxBitratePreference: String, CaseIterable {
    case p240
    case p480
    case p720
    case p1080
    case p4k

    var title: String {
        switch self {
        case .p240: "240p (0.5 Mbps)"
        case .p480: "480p (2 Mbps)"
        case .p720: "720p (4 Mbps)"
        case .p1080: "1080p (10 Mbps)"
        case .p4k:  "4K (40 Mbps)"
        }
    }

    var maxBitrate: Int {
        switch self {
        case .p240: 500_000
        case .p480: 2_000_000
        case .p720: 4_000_000
        case .p1080: 10_000_000
        case .p4k:  40_000_000
        }
    }

    var maxWidth: Int {
        switch self {
        case .p240: 426
        case .p480: 854
        case .p720: 1280
        case .p1080: 1920
        case .p4k:  3840
        }
    }

    var maxHeight: Int {
        switch self {
        case .p240: 240
        case .p480: 480
        case .p720: 720
        case .p1080: 1080
        case .p4k:  2160
        }
    }

    static var current: MaxBitratePreference {
        let raw = UserDefaults.standard.string(forKey: "maxStreamingBitrate")
        return raw.flatMap(MaxBitratePreference.init(rawValue:)) ?? .p1080
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
