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
struct SectionContainer<RowContent: View, HeaderContent: View>: View {
    @ViewBuilder let header: () -> HeaderContent

    let showHeader: Bool
    @ViewBuilder let content: () -> RowContent
    
    init(
        showHeader: Bool = true,
        @ViewBuilder content: @escaping () -> RowContent,
        @ViewBuilder header: @escaping () -> HeaderContent
    ) {
        self.header = header
        self.showHeader = showHeader
        self.content = content
    }
    
    var body: some View {
#if os(tvOS)
        Group {
            if showHeader {
                Section {
                    content()
                } header: {
                    header()
                }
            } else {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusSection()
#else
        VStack(alignment: .leading) {
            if showHeader {
                header()
                    .font(.title3.bold())
                    .scenePadding(.horizontal)
            }

            content()
        }
#endif
    }
}

