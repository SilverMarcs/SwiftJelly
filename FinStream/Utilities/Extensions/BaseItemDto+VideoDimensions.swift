import JellyfinAPI

extension BaseItemDto {
    /// Gets video dimensions for window sizing
    var videoDimensions: (width: Int, height: Int) {
        // Prefer the first VIDEO stream for dimensions
        let videoStream = mediaSources?
            .first?
            .mediaStreams?
            .first(where: { $0.type == .video })

        let width = videoStream?.width ?? 1024
        let height = videoStream?.height ?? 576

        // Guard against invalid 0/negative sizes sometimes reported by non-video streams
        if width <= 0 || height <= 0 {
            return (1024, 576)
        }
        return (width, height)
    }
}
