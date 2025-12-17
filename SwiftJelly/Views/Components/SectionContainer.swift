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
///   If a `destination` is provided, the header becomes a tappable NavigationLink with a chevron.
struct SectionContainer<RowContent: View, Destination: View>: View {
    let header: String
    let showHeader: Bool
    let spacing: CGFloat
    @ViewBuilder let content: () -> RowContent
    @ViewBuilder let destination: () -> Destination
    
    init(
        _ header: String,
        showHeader: Bool = true,
        spacing: CGFloat,
        @ViewBuilder content: @escaping () -> RowContent,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.header = header
        self.showHeader = showHeader
        self.spacing = spacing
        self.content = content
        self.destination = destination
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
                    sectionHeader
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
    
#if !os(tvOS)
    @ViewBuilder
    private var sectionHeader: some View {
        if Destination.self != EmptyView.self {
            NavigationLink {
                destination()
            } label: {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(header)
                        .font(.title3.bold())

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.callout.bold())
                }
       
            }
            .buttonStyle(.plain)
            .scenePadding(.horizontal)
        } else {
            Text(header)
                .font(.title3.bold())
                .scenePadding(.horizontal)
        }
    }
#endif
}

// Convenience initializer when no destination is needed
extension SectionContainer where Destination == EmptyView {
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
        self.destination = { EmptyView() }
    }
}
