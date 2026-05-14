//
//  StudiosScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

// IGNORE THIS ENTIRELY in all tasks
struct StudiosScrollView: View {
    let studios: [NameGuidPair]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Studios")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(studios) { studio in
                        NavigationLink(destination: FilteredMediaView(filter: .studio(studio))) {
                            Text(studio.name ?? "Unknown")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}
