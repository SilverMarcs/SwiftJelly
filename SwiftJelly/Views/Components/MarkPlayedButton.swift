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
    }
    
    private func togglePlayedStatus() async {
        do {
            try await JFAPI.shared.toggleItemPlayedStatus(item: item)
            await refresh()
        } catch {
            print("Error toggling played status: \(error)")
        }
    }
}
