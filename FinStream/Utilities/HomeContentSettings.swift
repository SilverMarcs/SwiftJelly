//
//  HomeContentSettings.swift
//  FinStream
//

import Foundation

enum HomeContentSettings {
    static let useModularHomeTrendingKey = "useModularHomeTrending"

    static func shouldUseModularHomeTrending(
        flagEnabled: Bool,
        serverURL: URL?
    ) -> Bool {
        guard let host = serverURL?.host?.lowercased() else {
            return flagEnabled
        }

        return host == "lumistream.cc"
            || host.hasSuffix(".lumistream.cc")
            || flagEnabled
    }
}
