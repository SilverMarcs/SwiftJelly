//
//  LibrariesView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 11.02.26.
//

import SwiftUI
import JellyfinAPI

struct LibrariesView: View {
    @State var libraries: [ViewListItem<BaseItemDto>] = withPlaceholderItems(size: 2)
    @State var isLoaded = false

    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: spacing) {
                ForEach(libraries) { library in
                    MediaNavigationLink(item: library.base) {
                        LandscapeImageView(item: library.base) {
                            Text(library.base?.name ?? "")
                                .font(.title)
                                .bold()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: columnMinimumWidth, height: columnMinimumHeight, alignment: .center)
                        .background(.background.secondary)
                    }
                    .cardBorder()
                }
            }
        } header: {
            Text("Libraries")
        }
        .task {
            await loadLibraries()
        }
    }
    
    private func loadLibraries() async {
        if isLoaded { return }

        do {
            let loaded = try await JFAPI.loadLibraries()
            isLoaded = true

            withAnimation {
                libraries.update(with: loaded)
            }
        } catch {
            print("Error loading Library: \(error.localizedDescription)")
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        30
        #else
        10
        #endif
    }

    private var columnMinimumWidth: CGFloat {
        #if os(tvOS)
        500
        #else
        250
        #endif
    }
    
    private var columnMinimumHeight: CGFloat { columnMinimumWidth * 0.5625 } // 16:9 Aspect Ratio
}
