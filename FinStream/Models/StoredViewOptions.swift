//
//  ViewOptions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 27.12.25.
//

import SwiftUI

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

extension CaseIterable where Self: Equatable {
    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let nextIdx = all.index(after: idx)
        return all[nextIdx == all.endIndex ? all.startIndex : nextIdx]
    }
}

