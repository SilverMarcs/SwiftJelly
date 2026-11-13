//
//  SeerUser.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerUser: Decodable, Hashable {
    let id: Int
    let displayName: String?
    let email: String?
}
