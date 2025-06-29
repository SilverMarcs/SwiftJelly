//
//  SubtitlePicker.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 30/06/2025.
//

import SwiftUI
import VLCUI

struct SubtitlePicker: View {
    let proxy: VLCVideoPlayer.Proxy
    let tracks: [MediaTrack]
    let selected: MediaTrack?
    @State private var selectedIndex: Int = 0

    var body: some View {
        Picker(selection: $selectedIndex) {
            ForEach(tracks, id: \.index) { track in
                Text(track.title.isEmpty ? "Track \(track.index + 1)" : track.title).tag(track.index)
            }
        } label: {
            Label("Subtitles", systemImage: "captions.bubble")
        }
        .labelsHidden()
        .onAppear {
            if let selected = selected {
                selectedIndex = selected.index
            }
        }
        .onChange(of: selectedIndex) {
            proxy.setSubtitleTrack(.absolute(selectedIndex))
        }
    }
}