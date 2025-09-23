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
            if let firstTagline = item.taglines?.first {
                Text(firstTagline)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }
            
            if let overview = item.overview {
                Text(overview)
                    .foregroundStyle(.secondary)
            }
        }
        .scenePadding(.horizontal)
    }
}
