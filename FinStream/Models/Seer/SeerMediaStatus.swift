//
//  SeerMediaStatus.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerMediaStatus: Int, Codable, Hashable {
    case unknown = 1
    case pending = 2
    case processing = 3
    case partiallyAvailable = 4
    case available = 5
    case blocklisted = 6
    case deleted = 7

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(Int.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var isRequestable: Bool {
        switch self {
        case .unknown, .deleted, .partiallyAvailable: true
        case .pending, .processing, .available, .blocklisted: false
        }
    }
}
