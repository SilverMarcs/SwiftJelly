//
//  SeerRequestState.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerRequestState: Equatable {
    case loading
    case requestable
    case partiallyAvailable
    case requested
    case available
    case unavailable

    init(status: SeerMediaStatus?) {
        switch status {
        case nil, .unknown, .deleted: self = .requestable
        case .pending, .processing: self = .requested
        case .partiallyAvailable: self = .partiallyAvailable
        case .available: self = .available
        case .blocklisted: self = .unavailable
        }
    }

    var title: String {
        switch self {
        case .loading, .requestable: "Request"
        case .partiallyAvailable: "Request More"
        case .requested: "Requested"
        case .available: "Available"
        case .unavailable: "Unavailable"
        }
    }

    var systemImage: String {
        switch self {
        case .loading, .requestable, .partiallyAvailable: "plus"
        case .requested: "clock"
        case .available: "checkmark"
        case .unavailable: "nosign"
        }
    }

    var canRequest: Bool {
        self == .requestable || self == .partiallyAvailable
    }
}
