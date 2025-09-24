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
        NavigationLink {
            PersonMediaView(person: person)
        } label: {
            personContent
        }
        .buttonStyle(.plain)
    }
    
    private var personContent: some View {
        VStack(alignment: .center, spacing: 10) {
            Group {
                if let url = ImageURLProvider.personImageURL(for: person) {
                    CachedAsyncImage(url: url, targetSize: 200)
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
            .aspectRatio(3/4, contentMode: .fill) 
            .clipShape(.rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.background.quinary, lineWidth: 1)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                if let name = person.name {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                
                if let role = person.role, !role.isEmpty {
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
        }
    }
}
