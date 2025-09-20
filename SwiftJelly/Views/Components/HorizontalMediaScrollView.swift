//
//  HorizontalMediaScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HorizontalMediaScrollView: View {
    let title: String
    let items: [BaseItemDto]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items) { item in
                        MediaNavigationLink(item: item)
                            .frame(width: 120)
                    }
                }
            }
        }
    }
}

#Preview {
    HorizontalMediaScrollView(
        title: "Recommended",
        items: [],
    )
}
