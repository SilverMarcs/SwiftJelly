import SwiftUI
import JellyfinAPI

struct RecentlyAddedView: View {
    let items: [BaseItemDto]
    var header: String
    
    var body: some View {
        if !items.isEmpty {
            // #if os(macOS)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(header)")
                    .font(.title2)
                    .bold()
                    .scenePadding(.leading)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items, id: \.id) { item in
                            MediaNavigationLink(item: item)
                                .frame(width: 150)
                        }
                    }
                }
            }
            // #else
            // Section {
            //     ScrollView(.horizontal, showsIndicators: false) {
            //         HStack(spacing: 12) {
            //             ForEach(items, id: \.id) { item in
            //                 MediaNavigationLink(item: item)
            //                     .frame(width: 150)
            //             }
            //         }
            //     }
            // } header: {
            //     #if os(macOS)
            //     HStack {
            //         Text(header)
            //             .font(.headline)
            //             .bold()
            //         Spacer()
            //     }
            //     .scenePadding(.horizontal)
            //     #else
            //     Text(header)
            //     #endif
            // }
            // .headerProminence(.increased)
            // #endif
        }
    }
}
