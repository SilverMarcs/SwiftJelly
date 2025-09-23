import Foundation
import JellyfinAPI

enum AVPlayerSupportChecker {
    static let supportedExtensions: Set<String> = [
        "mp4", "mov", "m4v", "mp3", "aac", "wav", "aiff", "hevc", "avi"
    ]
    
     static func isSupported(item: BaseItemDto) -> Bool {
         // Prefer container from first media source
         if let container = item.mediaSources?.first?.container?.lowercased(),
            supportedExtensions.contains(container) {
             return true
         }
        
         return false
     }
    
    static func isSupported(item: MediaItem) -> Bool {
        switch item {
        case .jellyfin(let jellyfinItem):
            return isSupported(item: jellyfinItem)
        case .local(let file):
            // Check file extension for local files
            let fileExtension = file.url.pathExtension.lowercased()
            return supportedExtensions.contains(fileExtension)
        }
    }
}
