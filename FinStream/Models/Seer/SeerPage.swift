//
//  SeerPage.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerPage<Result: Decodable>: Decodable {
    let page: Int?
    let totalPages: Int?
    let results: [Result]
}
