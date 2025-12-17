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
///   If a `destination` is provided, the header becomes a tappable `NavigationLink` with a chevron.
struct SectionContainer<RowContent: View, Destination: View>: View {
    let header: String
    let showHeader: Bool
    @ViewBuilder let content: () -> RowContent
    @ViewBuilder let destination: () -> Destination
    
    init(
        _ header: String,
        showHeader: Bool = true,
        @ViewBuilder content: @escaping () -> RowContent,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.header = header
        self.showHeader = showHeader
        self.content = content
        self.destination = destination
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
                if Destination.self == EmptyView.self {
                    Text(header)
                        .font(.title3.bold())
                        .scenePadding(.horizontal)
                } else {
                    NavigationLink {
                        destination()
                    } label: {
                        HStack(alignment: .lastTextBaseline) {
                            Text(header)
                                .font(.title3.bold())

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.callout.bold())
                        }
                    }
                    .buttonStyle(.plain)
                    .scenePadding(.horizontal)
                }
            }

            content()
        }
#endif
    }
}

// Convenience initializer when no destination is needed
extension SectionContainer where Destination == EmptyView {
    init(
        _ header: String,
        showHeader: Bool = true,
        @ViewBuilder content: @escaping () -> RowContent
    ) {
        self.header = header
        self.showHeader = showHeader
        self.content = content
        self.destination = { EmptyView() }
    }
}
