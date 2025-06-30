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
        Menu {
            if tracks.isEmpty {
                Text("No subtitles available")
                    .foregroundStyle(.secondary)
            } else {
                Picker(selection: $selectedIndex) {
                    ForEach(tracks, id: \.index) { track in
                        Text(track.title.isEmpty ? "Track \(track.index + 1)" : track.title).tag(track.index)
                    }
                } label: {
                    Label(selected?.title ?? "Disabled", systemImage: "captions.bubble")
                        .labelStyle(.titleOnly)
                }
                .onAppear {
                    if let selected = selected {
                        selectedIndex = selected.index
                    }
                }
                .onChange(of: selectedIndex) {
                    proxy.setSubtitleTrack(.absolute(selectedIndex))
                }
            }
        } label: {
            Label("Subtitles", systemImage: "captions.bubble")
                .imageScale(.large)
                .foregroundStyle(.secondary)
        }
        .labelStyle(.iconOnly)
        .menuIndicator(.hidden)
        .menuStyle(.button)
        .controlSize(.large)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
    }
}
