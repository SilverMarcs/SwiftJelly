//
//  SectionContainer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

/// A horizontally-scrolling shelf with a consistent section header treatment across platforms.
/// - tvOS: wraps the shelf in a `Section` (optional header) and applies `scrollClipDisabled`.
/// - other platforms: uses a `VStack` with a bold `title3` header and horizontal scene padding.
struct SectionContainer<RowContent: View>: View {
    let header: String
    let showHeader: Bool
    let spacing: CGFloat
    @ViewBuilder let content: () -> RowContent
    
    init(
        _ header: String,
        showHeader: Bool = true,
        spacing: CGFloat,
        @ViewBuilder content: @escaping () -> RowContent
    ) {
        self.header = header
        self.showHeader = showHeader
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        Group {
            let shelf = ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    content()
                }
#if !os(tvOS)
                .scenePadding(.horizontal)
#endif
            }
            
#if os(tvOS)
            if showHeader {
                Section(header) {
                    shelf
                        .scrollClipDisabled()
                }
            } else {
                shelf
                    .scrollClipDisabled()
            }
#else
            VStack(alignment: .leading, spacing: 8) {
                if showHeader {
                    Text(header)
                        .font(.title3.bold())
                        .scenePadding(.horizontal)
                }
                
                shelf
            }
#endif
        }
        #if os(tvOS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusSection()
        #endif
    }
}
