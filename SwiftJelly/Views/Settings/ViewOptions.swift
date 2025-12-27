//
//  ViewOptions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 27.12.25.
//

import SwiftUI

struct ViewOptions: View {
    #if os(tvOS)
    @AppStorage("tvOSNavigationStyle") private var navigationStyle: TVNavigationStyle = .tabBar
    #endif

    @AppStorage("episodeNamingStyle") private var episodeNamingStyle: EpisodeNamingStyle = .compact


    var body: some View {
        #if os(tvOS)
        Button {
            navigationStyle = navigationStyle.next()
        } label: {
            LabeledContent("Navigation Style", value: navigationStyle.title)
        }

        Button {
            episodeNamingStyle = episodeNamingStyle.next()
        } label: {
            LabeledContent("Naming Style", value: episodeNamingStyle.title)
        }
        #else
        Picker("Episode Naming Style", selection: $episodeNamingStyle) {
            Text(EpisodeNamingStyle.compact.title).tag(EpisodeNamingStyle.compact)
            Text(EpisodeNamingStyle.detailed.title).tag(EpisodeNamingStyle.detailed)
        }
        #endif
    }
}

#Preview {
    ViewOptions()
}
