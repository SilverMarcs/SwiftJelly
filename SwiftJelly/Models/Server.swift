//
//  Server.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import Foundation

struct Server: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var url: URL
    
    init(id: String = UUID().uuidString, name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}
