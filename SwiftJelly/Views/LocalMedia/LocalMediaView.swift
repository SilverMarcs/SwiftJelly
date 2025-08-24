//
//  LocalMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/08/2025.
//

import SwiftUI

struct LocalMediaView: View {    
    @State private var localMediaManager = LocalMediaManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(localMediaManager.recentFiles, id: \.url) { file in
                    LocalMediaRow(file: file)
                }
            }
            .overlay {
                if localMediaManager.recentFiles.isEmpty {
                    ContentUnavailableView(
                        "No Recent Media",
                        systemImage: "play.rectangle",
                        description: Text("Use the button above to open local media files")
                    )
                }
            }
        }
        .navigationTitle("Recent Files")
        .toolbar {
            LocalMediaFilePicker()
        }
    }
}


#Preview {
    LocalMediaView()
}
