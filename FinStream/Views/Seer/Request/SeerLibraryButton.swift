//
//  SeerLibraryButton.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI
import JellyfinAPI

struct SeerLibraryButton: View {
    let item: BaseItemDto

    var body: some View {
        NavigationLink(value: NavigationRoute.media(item)) {
            Label("Open in Library", systemImage: "play.rectangle")
                .labelStyle(.iconOnly)
                .heroActionIcon()
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .controlSize(.extraLarge)
        .tint(.primary)
        #endif
    }
}
