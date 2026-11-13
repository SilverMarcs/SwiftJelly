//
//  SeerDateParser.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerDateParser {
    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return try? Date(String(string.prefix(10)), strategy: .iso8601.year().month().day().dateSeparator(.dash))
    }

    static func year(from string: String?) -> Int? {
        guard let string, string.count >= 4 else { return nil }
        return Int(string.prefix(4))
    }
}
