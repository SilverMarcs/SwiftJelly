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
    @AppStorage("continueWatchingStyle") private var continueWatchingStyle: ContinueWatchingStyle = .combined

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
        
        Button {
            continueWatchingStyle = continueWatchingStyle.next()
        } label: {
            LabeledContent("Show Next Up & Resume", value: continueWatchingStyle.title)
        }
        #else
        Picker("Episode Naming Style", selection: $episodeNamingStyle) {
            Text(EpisodeNamingStyle.compact.title).tag(EpisodeNamingStyle.compact)
            Text(EpisodeNamingStyle.detailed.title).tag(EpisodeNamingStyle.detailed)
        }
        
        Picker("Show Next Up & Resume", selection: $continueWatchingStyle) {
            Text(ContinueWatchingStyle.combined.title).tag(ContinueWatchingStyle.combined)
            Text(ContinueWatchingStyle.separated.title).tag(ContinueWatchingStyle.separated)
        }
        #endif
    }
}

#Preview {
    ViewOptions()
}
