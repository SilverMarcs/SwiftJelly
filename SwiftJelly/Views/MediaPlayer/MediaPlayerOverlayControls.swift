import SwiftUI

struct MediaPlayerOverlayControls: View {
    @Bindable var model: MediaPlaybackViewModel

    var body: some View {
        VStack {
            Spacer()
            
            if model.isAutoLoadingNext {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }

            HStack {
                if model.shouldShowSkipIntro {
                    Button("Skip Intro", systemImage: "forward.end") {
                        Task { await model.skipIntro() }
                    }
                }

                Spacer()

                if model.shouldShowNextEpisode {
                    Button("Next Episode", systemImage: "forward.end.alt") {
                        Task { await model.transitionToNextEpisode() }
                    }
                }
            }
            .buttonStyle(.glass)
            .padding()
            #if os(macOS)
            .controlSize(.large)
            #endif
        }
        .allowsHitTesting(model.shouldShowSkipIntro || model.shouldShowNextEpisode)
    }
}
