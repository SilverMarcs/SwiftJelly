//
//  MediaNavigationLink.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI
import JellyfinAPI

struct MediaNavigationLink<Label: View>: View {
    let item: BaseItemDto?
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        if let item {
            let destinationItem = item.type == .episode ? item.toSeries() ?? item : item

            NavigationLink(value: NavigationRoute.media(destinationItem)) {
                label()
            }
            .adaptiveCardButtonStyle()
        } else {
            Button(action: { }) {
                label()
            }
            .adaptiveCardButtonStyle()
            #if !os(tvOS)
            .disabled(true)
            #endif
        }
    }
}
