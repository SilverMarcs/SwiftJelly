import SwiftUI
import JellyfinAPI

struct MarkPlayedButton: View {
    var item: BaseItemDto?
    var markAllEpisodesWatched: (() async -> Void)? = nil
    var canMarkAllEpisodesWatched = true
    @Environment(\.refresh) private var refresh
    
    var isPlayed: Bool {
        item?.userData?.isPlayed ?? false
    }
    
    var body: some View {
        Button {
            Task {
                if let markAllEpisodesWatched {
                    await markAllEpisodesWatched()
                } else {
                    await togglePlayedStatus()
                }
            }
        } label: {
            Label(markAllEpisodesWatched == nil ? "Toggle Watched" : "Mark Season Watched", systemImage: "checkmark")
                .labelStyle(.iconOnly)
                .heroActionIcon()
        }
        .disabled(markAllEpisodesWatched != nil && !canMarkAllEpisodesWatched)
        .foregroundStyle(isPlayed ? Color.green : Color.primary)
        #if os(tvOS)
        .controlSize(.regular)
        #else
        .controlSize(.extraLarge)
        #endif
        .buttonBorderShape(.circle)
        .buttonStyle(.glass)
    }
    
    private func togglePlayedStatus() async {
        do {
            if let item = item {
                try await JFAPI.toggleItemPlayedStatus(item: item)
                await refresh()
            }
        } catch {
            print("Error toggling played status: \(error)")
        }
    }
}
