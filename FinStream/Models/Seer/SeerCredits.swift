//
//  SeerCredits.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerCredits: Decodable, Hashable {
    let cast: [SeerCreditPerson]?
    let crew: [SeerCreditPerson]?
}

struct SeerCreditPerson: Decodable, Hashable {
    let id: Int
    let name: String
    let character: String?
    let job: String?
    let profilePath: String?
}
