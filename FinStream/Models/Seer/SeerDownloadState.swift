//
//  SeerDownloadState.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import SwiftUI

/// The queue status of a download as reported by Sonarr/Radarr through Seer.
enum SeerDownloadState: String, Decodable, Hashable {
    case downloading
    case queued
    case paused
    case delay
    case completed
    case warning
    case failed
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: rawValue.lowercased()) ?? .unknown
    }

    var title: String {
        switch self {
        case .downloading: "Downloading"
        case .queued: "Queued"
        case .paused: "Paused"
        case .delay: "Delayed"
        case .completed: "Importing"
        case .warning: "Warning"
        case .failed: "Failed"
        case .unknown: "Processing"
        }
    }

    var tint: Color {
        switch self {
        case .downloading, .completed, .unknown: .indigo
        case .queued, .delay, .paused: .gray
        case .warning: .orange
        case .failed: .red
        }
    }
}
