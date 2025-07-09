import Foundation
import JellyfinAPI

struct AVPlayerSupportChecker {
    static let supportedExtensions: Set<String> = [
        "mp4", "mov", "m4v", "mp3", "aac", "wav", "aiff", "hevc", "avi"
    ]
    
    static func isSupported(url: URL) -> Bool {
        print(url)
        guard let ext = url.pathExtension.lowercased().split(separator: "?").first else { return false }
        let supported = supportedExtensions.contains(String(ext))
        
        print(supported)
        return supported
    }
    
    static func isSupported(item: BaseItemDto, url: URL? = nil) -> Bool {
        // Prefer container from first media source
        if let container = item.mediaSources?.first?.container?.lowercased(),
           supportedExtensions.contains(container) {
            return true
        }
        // Fallback to url extension if available
        if let url = url {
            let ext = url.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                return true
            }
        }
        return false
    }
}
