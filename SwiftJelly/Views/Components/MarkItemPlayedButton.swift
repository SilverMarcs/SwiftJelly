import SwiftUI
import JellyfinAPI

struct MarkPlayedButton: View {
    let item: BaseItemDto
    @State private var isPlayed: Bool
    
    init(item: BaseItemDto) {
        self.item = item
        self._isPlayed = State(initialValue: item.userData?.isPlayed == true)
    }
    
    var body: some View {
        Button {
            Task {
                await togglePlayedStatus()
            }
        } label: {
            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundStyle(isPlayed ? .accent : .secondary)
        }
    }
    
    private func togglePlayedStatus() async {
        do {
            try await JFAPI.shared.toggleItemPlayedStatus(item: item)
            await MainActor.run {
                isPlayed.toggle()
            }
        } catch {
            print("Error toggling played status: \(error)")
        }
    }
}
