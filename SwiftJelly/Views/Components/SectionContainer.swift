//
//  SectionContainer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

/// A container that wraps content in a Section on tvOS, or a VStack with styled header on other platforms.
/// On tvOS, content is wrapped in Section with scrollClipDisabled applied.
/// On other platforms, content is wrapped in a VStack with a bold title3 header.
struct SectionContainer<Content: View>: View {
    let header: String
    let showHeader: Bool
    @ViewBuilder let content: () -> Content
    
    init(_ header: String, showHeader: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.showHeader = showHeader
        self.content = content
    }
    
    var body: some View {
        #if os(tvOS)
        if showHeader {
            Section(header) {
                content()
                    .scrollClipDisabled()
            }
        } else {
            content()
                .scrollClipDisabled()
        }
        #else
        VStack(alignment: .leading, spacing: 8) {
            if showHeader {
                Text(header)
                    .font(.title3.bold())
                    .scenePadding(.horizontal)
            }
            
            content()
        }
        #endif
    }
}
