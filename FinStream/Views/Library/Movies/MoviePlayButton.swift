import SwiftUI
import JellyfinAPI

struct MoviePlayButton: View {
    let item: BaseItemDto

    var body: some View {
        PlayMediaButton(item: item) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")

                if item.userData?.isPlayed == true {
                    Text("Play Again")
                } else if let progress = item.playbackProgress, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .tint(.primary)
                        #if os(tvOS)
                        .frame(width: 60)
                        #else
                        .controlSize(.mini)
                        .frame(width: 40)
                        #endif

                    if let remaining = item.timeRemainingString {
                        Text(remaining)
                    }
                } else {
                    Text("Play")
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .animation(.default, value: item.userData?.isPlayed)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .tint(Color(.accent).secondary)
        .controlSize(.extraLarge)
        #endif
    }
}

#Preview {
    VStack(spacing: 20) {
        // Unplayed
        MoviePlayButton(item: BaseItemDto(runTimeTicks: 72000000000))

        // In progress
        MoviePlayButton(item: BaseItemDto(
            runTimeTicks: 72000000000,
            userData: UserItemDataDto(playbackPositionTicks: 30000000000)
        ))

        // Played
        MoviePlayButton(item: BaseItemDto(
            runTimeTicks: 72000000000,
            userData: UserItemDataDto(isPlayed: true)
        ))
    }
    .padding()
}
