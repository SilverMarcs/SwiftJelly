//
//  AppearanceOptions.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct AppearanceOptions: View {
    @AppStorage("heroCarouselSource") private var heroCarouselSource: HeroCarouselSource = .jellyfinPopular

    private var isSeerConfigured: Bool {
        DataManager.shared.server?.seer?.isAuthenticated == true
    }

    private var availableSources: [HeroCarouselSource] {
        HeroCarouselSource.availableCases(isSeerConfigured: isSeerConfigured)
    }

    private var selection: Binding<HeroCarouselSource> {
        Binding(
            get: { heroCarouselSource.effective(isSeerConfigured: isSeerConfigured) },
            set: { heroCarouselSource = $0 }
        )
    }

    var body: some View {
        #if os(tvOS)
        Button {
            let sources = availableSources
            let index = sources.firstIndex(of: selection.wrappedValue) ?? 0
            selection.wrappedValue = sources[(index + 1) % sources.count]
        } label: {
            LabeledContent("Hero Carousel", value: selection.wrappedValue.title)
        }
        #else
        Picker("Hero Carousel", selection: selection) {
            ForEach(availableSources, id: \.self) { source in
                Text(source.title).tag(source)
            }
        }
        #endif
    }
}
