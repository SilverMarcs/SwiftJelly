//
//  LibraryCard.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI
import Get

struct LibraryCard: View {
    let library: BaseItemDto
    @EnvironmentObject private var dataManager: DataManager
    
    private var server: Server? {
        guard let currentUser = dataManager.currentUser else { return nil }
        return dataManager.servers.first { $0.id == currentUser.serverID }
    }
    
    private var user: User? {
        dataManager.currentUser
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: ImageURLProvider.primaryImageURL(for: library, maxWidth: 300)) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: iconName)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(library.name ?? "Unknown Library")
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 150)
    }
    
    private var primaryImageURL: URL? {
        guard let server = server,
              let user = user,
              let client = dataManager.jellyfinClient(for: user, server: server),
              let id = library.id else { return nil }
        
        let maxWidth: CGFloat = 300
        
        if let primaryTag = getImageTag(for: .primary, from: library) {
            let parameters = Paths.GetItemImageParameters(
                maxWidth: Int(maxWidth),
                tag: primaryTag
            )
            let request = Paths.getItemImage(
                itemID: id,
                imageType: ImageType.primary.rawValue,
                parameters: parameters
            )
            return client.fullURL(with: request)
        }
        
        return nil
    }
    
    private func getImageTag(for type: ImageType, from item: BaseItemDto) -> String? {
        switch type {
        case .backdrop:
            return item.backdropImageTags?.first
        case .screenshot:
            return item.screenshotImageTags?.first
        default:
            return item.imageTags?[type.rawValue]
        }
    }
    
    private var iconName: String {
        switch library.collectionType {
        case .movies:
            return "film"
        case .tvshows:
            return "tv"
        case .music:
            return "music.note"
        case .books:
            return "book"
        case .photos:
            return "photo"
        default:
            return "folder"
        }
    }
}
