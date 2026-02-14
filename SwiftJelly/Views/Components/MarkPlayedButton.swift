import SwiftUI
import JellyfinAPI

struct MarkPlayedButton: View {
    var item: BaseItemDto?
    @Environment(\.refresh) private var refresh
    
    var isPlayed: Bool {
        item?.userData?.isPlayed ?? false
    }
    
    var body: some View {
        Button {
            Task {
                await togglePlayedStatus()
            }
        } label: {
            Image(systemName: "checkmark")
                .fontWeight(.medium)
                .animation(.snappy, value: isPlayed)
        }
        .tint((isPlayed == true) ? Color.green : Color.primary)
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
