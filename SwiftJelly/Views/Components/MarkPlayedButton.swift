import SwiftUI
import JellyfinAPI

struct MarkPlayedButton: View {
    let item: BaseItemDto
    @Environment(\.refresh) private var refresh
    
    var body: some View {
        Button {
            Task {
                await togglePlayedStatus()
            }
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle((item.userData?.isPlayed == true) ? .accent : .secondary)
                .fontWeight(.semibold)
                .animation(.snappy, value: item.userData?.isPlayed)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        #if os(macOS)
        .controlSize(.extraLarge)
        #else
        .controlSize(.large)
        #endif
    }
    
    private func togglePlayedStatus() async {
        do {
            try await JFAPI.toggleItemPlayedStatus(item: item)
            await refresh()
        } catch {
            print("Error toggling played status: \(error)")
        }
    }
}
