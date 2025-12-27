//
//  SectionContainer.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import SwiftUI

/// A section wrapper with a consistent header treatment across platforms.
/// - tvOS: wraps the content in a `Section` (optional header).
/// - other platforms: uses a `VStack` with a bold `title3` header and horizontal scene padding.
struct SectionContainer<RowContent: View>: View {
    let header: String
    let showHeader: Bool
    @ViewBuilder let content: () -> RowContent
    
    init(
        _ header: String,
        showHeader: Bool = true,
        @ViewBuilder content: @escaping () -> RowContent
    ) {
        self.header = header
        self.showHeader = showHeader
        self.content = content
    }
    
    var body: some View {
#if os(tvOS)
        Group {
            if showHeader {
                Section(header) { content() }
            } else {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusSection()
#else
        VStack(alignment: .leading) {
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
