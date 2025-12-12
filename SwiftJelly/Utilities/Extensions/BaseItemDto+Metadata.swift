//
//  BaseItemDto+Metadata.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 23/10/2025.
//

import AVKit
import JellyfinAPI

extension BaseItemDto {
    /// Creates AVMetadataItems for the media player
    func createMetadataItems() async -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = []
        
        // Title
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = metadataTitle as NSString
        titleItem.extendedLanguageTag = "und"
        metadata.append(titleItem)
        
        // Subtitle (for TV shows only)
        if let subtitle = seasonEpisodeString {
            let subtitleItem = AVMutableMetadataItem()
            subtitleItem.identifier = .iTunesMetadataTrackSubTitle
            subtitleItem.value = subtitle as NSString
            subtitleItem.extendedLanguageTag = "und"
            metadata.append(subtitleItem)
        }
        
        // Artwork
        if let artworkData = await loadArtwork() {
            let artworkItem = AVMutableMetadataItem()
            artworkItem.identifier = .commonIdentifierArtwork
            artworkItem.dataType = kCMMetadataBaseDataType_PNG as String
            artworkItem.value = artworkData as NSData
            metadata.append(artworkItem)
        }
        
        return metadata
    }
    
    private var metadataTitle: String {
        if type == .movie {
            return name ?? "Unknown"
        } else {
            return seriesName ?? name ?? "Unknown"
        }
    }
    
    private func loadArtwork() async -> Data? {
        guard let url = ImageURLProvider.imageURL(for: self, type: .primary) else {
            return nil
        }
        
        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            print("Failed to load artwork: \(error)")
            return nil
        }
    }
}
