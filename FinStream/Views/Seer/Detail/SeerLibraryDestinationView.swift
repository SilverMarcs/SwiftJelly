//
//  SeerLibraryDestinationView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerLibraryDestinationView: View {
    let item: BaseItemDto

    var body: some View {
        switch item.type {
        case .series:
            ShowDetailView(item: item)
        default:
            MovieDetailView(item: item)
        }
    }
}
