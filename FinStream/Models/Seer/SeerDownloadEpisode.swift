//
//  SeerDownloadEpisode.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

import Foundation

struct SeerDownloadEpisode: Decodable, Hashable {
    let seasonNumber: Int?
    let episodeNumber: Int?
}
