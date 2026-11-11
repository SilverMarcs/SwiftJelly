import Foundation

enum HLSSubtitleCompatibility {
    /// Jellyfin 10.x adds a fixed 10-second MPEG-TS map to WebVTT, even for
    /// fMP4 video starting at zero. Keep absolute cue times and normalize the map.
    static func make(playlist: String, sourceURL: URL, segmentPaths: [URL: String] = [:]) throws -> String {
        let lines = normalizedLines(in: playlist)
        guard lines.first == "#EXTM3U", lines.contains(where: { $0.hasPrefix("#EXTINF:") }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return try lines.map { line in
            guard !line.isEmpty, !line.hasPrefix("#") else { return line }
            let url = try segmentURL(line, sourceURL: sourceURL)
            return segmentPaths[url] ?? url.absoluteString
        }.joined(separator: "\n")
    }

    static func segments(in playlist: String, sourceURL: URL) throws -> [URL] {
        try normalizedLines(in: playlist).filter { !$0.isEmpty && !$0.hasPrefix("#") }.map {
            try segmentURL($0, sourceURL: sourceURL)
        }
    }

    static func normalizeWebVTT(_ text: String, mpegTimestamp: Int64?) throws -> String {
        var lines = normalizedLines(in: text)
        guard lines.first?.hasPrefix("WEBVTT") == true else { throw CocoaError(.fileReadCorruptFile) }
        guard let mpegTimestamp else { return text }
        let headerEnd = lines.firstIndex(of: "") ?? lines.endIndex
        if let map = lines[..<headerEnd].first(where: { $0.hasPrefix("X-TIMESTAMP-MAP=") }),
           !map.contains("MPEGTS:900000,LOCAL:00:00:00.000") {
            return text
        }
        let header = lines[..<headerEnd].filter { !$0.hasPrefix("X-TIMESTAMP-MAP=") }
        lines = Array(header) + ["X-TIMESTAMP-MAP=MPEGTS:\(mpegTimestamp),LOCAL:00:00:00.000"] + lines[headerEnd...]
        return lines.joined(separator: "\n")
    }

    private static func normalizedLines(in text: String) -> [String] {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "\u{feff}"))
            .replacing("\r\n", with: "\n").replacing("\r", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func segmentURL(_ line: String, sourceURL: URL) throws -> URL {
        guard let url = URL(string: line, relativeTo: sourceURL)?.absoluteURL,
              url.pathExtension.lowercased() == "vtt",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        components.queryItems = (components.queryItems ?? []).filter {
            !["addvtttimemap", "copytimestamps"].contains($0.name.lowercased())
        } + [URLQueryItem(name: "CopyTimestamps", value: "true"), URLQueryItem(name: "AddVttTimeMap", value: "false")]
        guard let url = components.url else { throw URLError(.badURL) }
        return url
    }
}
