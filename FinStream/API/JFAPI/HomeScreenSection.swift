//
//  HomeScreenSection.swift
//  FinStream
//

import Foundation

/// A home row configured by the optional Home Screen Sections Jellyfin plugin.
nonisolated struct HomeScreenSection: Decodable, Sendable {
    /// The section identifier used to fetch the row's items.
    let section: String
    let displayText: String?
    /// Extra data the plugin needs to fetch the row, such as a collection ID.
    let additionalData: String?

    enum CodingKeys: String, CodingKey {
        case section = "Section"
        case displayText = "DisplayText"
        case additionalData = "AdditionalData"
    }

    /// The response envelope returned by `/HomeScreen/Sections`.
    nonisolated struct List: Decodable, Sendable {
        let items: [HomeScreenSection]

        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }
}
