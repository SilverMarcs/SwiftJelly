//
//  PersonView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/07/2025.
//

import SwiftUI
import JellyfinAPI
import CachedAsyncImage

struct PersonView: View {
    let person: BaseItemPerson
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Group {
                if let url = ImageURLProvider.personImageURL(for: person) {
                    CachedAsyncImage(url: url, targetSize: CGSize(width: 200, height: 200))
                } else {
                    Rectangle()
                        .foregroundStyle(.quaternary)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 80, height: 80)
            .scaledToFill() // not working
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.secondary, lineWidth: 1)
            )
            
            VStack(spacing: 2) {
                if let name = person.name {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                if let role = person.role, !role.isEmpty {
                    Text("as \(role)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}
