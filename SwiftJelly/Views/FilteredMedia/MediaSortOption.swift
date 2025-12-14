//
//  MediaSortOption.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 22/09/2025.
//

import Foundation

enum MediaSortOption: String, CaseIterable {
    case random = "Random"
    case nameAscending = "Name A-Z"
    case nameDescending = "Name Z-A"
    case ratingDescending = "Highest Rated"
    case ratingAscending = "Lowest Rated"
    case criticRatingDescending = "Best Critic Score"
    case criticRatingAscending = "Worst Critic Score"
    case yearDescending = "Newest First"
    case yearAscending = "Oldest First"
    
    var systemImage: String {
        switch self {
        case .random: "shuffle"
        case .nameAscending, .nameDescending: "textformat"
        case .ratingDescending, .ratingAscending: "star.fill"
        case .criticRatingDescending, .criticRatingAscending: "checkmark.seal.fill"
        case .yearDescending, .yearAscending: "calendar"
        }
    }
}
