//
//  PlaybackOptions.swift
//  SwiftJelly
//

import SwiftUI

struct PlaybackOptions: View {
    @AppStorage("maxStreamingBitrate") private var maxStreamingBitrate: MaxBitratePreference = .p1080

    var body: some View {
        #if os(tvOS)
        Button {
            maxStreamingBitrate = maxStreamingBitrate.next()
        } label: {
            LabeledContent("Max Streaming Quality", value: maxStreamingBitrate.title)
        }
        #else
        Picker("Max Streaming Quality", selection: $maxStreamingBitrate) {
            ForEach(MaxBitratePreference.allCases, id: \.self) { pref in
                Text(pref.title).tag(pref)
            }
        }
        #endif
    }
}

#Preview {
    PlaybackOptions()
}
