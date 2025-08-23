//
//  LocalMediaFilePicker.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct LocalMediaFilePicker: View {
    @State private var isPickerPresented = false
    let onFileSelected: (LocalMediaFile) -> Void
    
    var body: some View {
        Button("Open Local Media") {
            isPickerPresented = true
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [
                .movie,
                .video,
                .audio,
                UTType("public.audiovisual-content") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let localFile = LocalMediaFile(url: url)
                    onFileSelected(localFile)
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
    }
}
