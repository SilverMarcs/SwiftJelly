import SwiftUI
import JellyfinAPI

struct NextUpView: View {
    let items: [BaseItemDto]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Next Up")
                    .font(.title.bold())
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(items) { item in
                            NextUpPortraitCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
