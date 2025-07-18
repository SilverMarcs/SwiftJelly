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
                .font(.title2)
                .foregroundStyle((item.userData?.isPlayed == true) ? .accent : .secondary)
        }
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
