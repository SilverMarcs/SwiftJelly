import SwiftUI
import JellyfinAPI

struct NextUpView: View {
    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Up")
                .font(.title.bold())
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            } else if let error = error {
                Text("Failed to load Next Up: \(error.localizedDescription)")
                    .foregroundStyle(.secondary)
            } else {
                let filteredItems = items.filter { item in
                    guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else {
                        // If no watchtime, include
                        return true
                    }
                    // Exclude if any watchtime
                    return ticks == 0
                }
                if filteredItems.isEmpty {
                    Text("No Next Up items.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                NextUpPortraitCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .task {
            await fetchNextUp()
        }
    }

    private func fetchNextUp() async {
        isLoading = true
        error = nil
        do {
            self.items = try await JFAPI.shared.loadNextUpItems()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
