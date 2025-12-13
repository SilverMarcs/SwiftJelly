//
//  OverviewView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/09/2025.
//

import SwiftUI
import JellyfinAPI

struct OverviewView: View {
    let item: BaseItemDto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let overview = item.overview ??  item.taglines?.first {
                Text(overview)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
        }
        .scenePadding(.horizontal)
    }
}
