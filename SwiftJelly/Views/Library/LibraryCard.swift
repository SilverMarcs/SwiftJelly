//
//  LibraryCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI
import Get

struct LibraryCard: View {
    let library: BaseItemDto

    var body: some View {
        LandscapeImageView(item: library)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
