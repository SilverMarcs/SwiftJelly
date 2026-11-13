//
//  SearchSourcePicker.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SearchSourcePicker: View {
    @Binding var source: SearchSource

    var body: some View {
        #if os(tvOS)
        Picker("Source", selection: $source) {
            ForEach(SearchSource.allCases) { source in
                Text(source.title).tag(source)
            }
        }
        .pickerStyle(.segmented)
        #else
        Menu {
            Picker("Source", selection: $source) {
                ForEach(SearchSource.allCases) { source in
                    Label(source.title, systemImage: source.systemImage).tag(source)
                }
            }
        } label: {
            Label("Source", systemImage: source.systemImage)
        }
        #endif
    }
}
