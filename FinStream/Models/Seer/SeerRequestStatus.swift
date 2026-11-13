//
//  SeerRequestStatus.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerRequestStatus: Int, Codable, Hashable {
    case pending = 1
    case approved = 2
    case declined = 3
    case failed = 4
    case completed = 5

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(Int.self)
        self = Self(rawValue: rawValue) ?? .pending
    }
}
