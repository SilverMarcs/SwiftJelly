//
//  ContentViewOld.swift
//  JellySwift
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ContentViewOld: View {

    @StateObject
    private var viewModel = ContentViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            VLCVideoPlayer(configuration: viewModel.configuration)
                .proxy(viewModel.proxy)
                .onStateUpdated(viewModel.onStateUpdated)
                .onSecondsUpdated(viewModel.onSecondsUpdated)

            OverlayView(viewModel: viewModel)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}


import Combine
import Foundation
import VLCUI

class ContentViewModel: ObservableObject {

    @Published
    var seconds: Duration = .zero
    @Published
    var playerState: VLCVideoPlayer.State = .opening
    @Published
    var position: Float = 0
    @Published
    var totalSeconds: Duration = .zero
    @Published
    var isRecording = false

    let proxy: VLCVideoPlayer.Proxy = .init()

    var configuration: VLCVideoPlayer.Configuration {
        var configuration = VLCVideoPlayer
            .Configuration(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!)
        configuration.autoPlay = true

        return configuration
    }

    var positiveSeconds: Int {
        Int(seconds.components.seconds)
    }

    var negativeSeconds: Int {
        Int((totalSeconds - seconds).components.seconds)
    }

    func onStateUpdated(_ newState: VLCVideoPlayer.State, _ playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        playerState = newState
    }

    func onSecondsUpdated(_ newSeconds: Duration, _ playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        seconds = newSeconds
        totalSeconds = .milliseconds(playbackInformation.length)
        position = playbackInformation.position
    }
}


import SwiftUI
import VLCUI

struct OverlayView: View {

    @ObservedObject
    var viewModel: ContentViewModel
    @State
    private var isScrubbing: Bool = false
    @State
    private var currentPosition: Float = 0

    var body: some View {
        HStack(spacing: 20) {

            Button("Record", systemImage: "record.circle") {
                if viewModel.isRecording {
                    viewModel.proxy.stopRecording()
                    viewModel.isRecording = false
                } else {
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    print("Recording Path:", documentsPath.path)
                    viewModel.proxy.startRecording(atPath: documentsPath.path)
                    viewModel.isRecording = true
                }
            }
            .foregroundStyle(viewModel.isRecording ? .red : .accentColor)
            .symbolEffect(.pulse, value: viewModel.isRecording)

            Button("Go backward", systemImage: "gobackward.15") {
                viewModel.proxy.jumpBackward(15)
            }

            Button {
                if viewModel.playerState == .playing {
                    viewModel.proxy.pause()
                } else {
                    viewModel.proxy.play()
                }
            } label: {
                Group {
                    if viewModel.playerState == .playing {
                        Image(systemName: "pause.circle.fill")
                    } else if viewModel.playerState == .buffering {
                        ProgressView()
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                }
                .frame(maxWidth: 30)
            }

            Button("Go forward", systemImage: "goforward.15") {
                viewModel.proxy.jumpForward(15)
            }

            HStack(spacing: 5) {
//                Text(viewModel.positiveSeconds, format: .runtime)
//                    .frame(width: 50)

                Slider(
                    value: $currentPosition,
                    in: 0 ... Float(1.0)
                ) { isEditing in
                    isScrubbing = isEditing
                }

//                Text(viewModel.negativeSeconds, format: .runtime)
//                    .frame(width: 50)
            }
            .font(.system(size: 18, weight: .regular, design: .default))
            .monospacedDigit()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 28, weight: .regular, design: .default))
        .onChange(of: isScrubbing) {
            guard !isScrubbing else { return }

            let newSeconds = viewModel.totalSeconds * Double(currentPosition)
            viewModel.proxy.setSeconds(newSeconds)
        }
        .onChange(of: viewModel.position) {
            guard !isScrubbing else { return }
            currentPosition = viewModel.position
        }
    }
}
