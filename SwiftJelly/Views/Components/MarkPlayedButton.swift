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
                .fontWeight(.semibold)
                .animation(.snappy, value: item.userData?.isPlayed)
        }
        .tint((item.userData?.isPlayed == true) ? Color.green : Color.primary)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.extraLarge)
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
