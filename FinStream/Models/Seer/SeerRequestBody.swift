//
//  SeerRequestBody.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerRequestBody: Encodable {
    let mediaType: SeerMediaType
    let mediaID: Int
    let seasons: [Int]?
    let is4k = false

    enum CodingKeys: String, CodingKey {
        case mediaType
        case mediaID = "mediaId"
        case seasons
        case is4k
    }
}
