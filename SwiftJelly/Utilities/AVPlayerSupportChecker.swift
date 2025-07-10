import Foundation
import JellyfinAPI

struct AVPlayerSupportChecker {
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
}
