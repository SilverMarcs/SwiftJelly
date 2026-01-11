//
//  PlaybackManager.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 11/01/2026.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable final class PlaybackManager {
    static let shared = PlaybackManager()
    private init() {}

    /// The view model for the currently active playback session, if any.
    private(set) var viewModel: MediaPlaybackViewModel?

    /// A closure to call when playback ends to refresh the UI.
    var refreshHandler: (() async -> Void)?

    /// Whether the player UI should be presented (non-macOS platforms).
    var isPlayerPresented = false

    /// The currently playing item, if any.
    var currentItem: BaseItemDto? {
        viewModel?.item
    }

    /// Whether playback is currently active.
    var isPlaying: Bool {
        viewModel?.player != nil
    }

    /// Starts playback for the given item and optional refresh handler.
    /// - Parameters:
    ///   - item: The item to play.
    ///   - refresh: An optional closure to call when playback ends.
    func startPlayback(for item: BaseItemDto, refresh: (() async -> Void)? = nil) {
        refreshHandler = refresh
        viewModel = MediaPlaybackViewModel(item: item)
        isPlayerPresented = true
    }

    /// Called when playback ends to clean up and trigger the refresh handler.
    func endPlayback() async {
        if let handler = refreshHandler {
            await handler()
            refreshHandler = nil
        }
        viewModel = nil
    }
}
