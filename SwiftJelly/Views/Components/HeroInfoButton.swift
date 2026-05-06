//
//  HeroInfoButton.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 06/05/2026.
//

import SwiftUI
import JellyfinAPI

/// An "info" affordance shown alongside hero play buttons. Navigates to the
/// item's detail view — the same destination as tapping the backdrop.
struct HeroInfoButton: View {
    let item: BaseItemDto

    var body: some View {
        NavigationLink(value: item) {
            Image(systemName: "info")
        }
        .buttonStyle(.glass)
        .tint(.primary)
        .buttonBorderShape(.circle)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .controlSize(.extraLarge)
        #endif
    }
}
