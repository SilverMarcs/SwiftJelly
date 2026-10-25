import Foundation

enum HLSManifest {
    /// Label the in-band audio in each complete Jellyfin stream. Selecting audio
    /// lets AVPlayer change video variants without fabricated or missing media.
    static func make(
        master: String,
        sourceURL: URL,
        renditions: [HLSAudioRendition],
        selectedIndex: Int,
        subtitlePlaylistPaths: [URL: String] = [:]
    ) throws -> String {
        let lines = master.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.first == "#EXTM3U",
              lines.contains(where: { $0.hasPrefix("#EXT-X-STREAM-INF:") }) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var result = ["#EXTM3U", "#EXT-X-VERSION:6"]
        for rendition in renditions {
            var values = [
                "TYPE=AUDIO", "GROUP-ID=\"finstream-audio-\(rendition.streamIndex)\"",
                "NAME=\"\(quoted(rendition.name))\"",
                "DEFAULT=YES",
                "AUTOSELECT=YES", "CHANNELS=\"\(rendition.channels)\"",
                "CHARACTERISTICS=\"\(HLSMediaIdentity.audio(rendition.streamIndex))\"",
            ]
            if let language = rendition.language, !language.isEmpty {
                values.append("LANGUAGE=\"\(quoted(language))\"")
            }
            result.append("#EXT-X-MEDIA:" + values.joined(separator: ","))
        }

        var variantAttributes: String?
        var variants: [(String, URL)] = []
        for line in lines.dropFirst() {
            if line.hasPrefix("#EXT-X-VERSION:") {
                if let version = Int(line.dropFirst("#EXT-X-VERSION:".count)), version > 6 {
                    result[1] = line
                }
                continue
            }
            if !renditions.isEmpty, line.hasPrefix("#EXT-X-MEDIA:"), attributes(in: line)["TYPE"] == "AUDIO" {
                continue
            }
            if line.hasPrefix("#EXT-X-STREAM-INF:") {
                variantAttributes = line
            } else if line.hasPrefix("#"), let uri = attributes(in: line)["URI"] {
                guard let absoluteURL = URL(string: uri, relativeTo: sourceURL)?.absoluteURL else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let uri = attributes(in: line)["TYPE"] == "SUBTITLES"
                    ? subtitlePlaylistPaths[absoluteURL] ?? absoluteURL.absoluteString
                    : absoluteURL.absoluteString
                var rewritten = replacingAttribute("URI", with: "\"\(uri)\"", in: line)
                if attributes(in: line)["TYPE"] == "SUBTITLES" {
                    let parts = absoluteURL.pathComponents
                    if let position = parts.firstIndex(where: { $0.lowercased() == "subtitles" }), parts.indices.contains(position + 1), let index = Int(parts[position + 1]) {
                        let existing = attributes(in: rewritten)["CHARACTERISTICS"].map { $0 + "," } ?? ""
                        rewritten = replacingAttribute("CHARACTERISTICS", with: "\"\(existing)\(HLSMediaIdentity.subtitle(index))\"", in: rewritten)
                    }
                }
                result.append(rewritten)
            } else if !line.hasPrefix("#") {
                guard let absoluteURL = URL(string: line, relativeTo: sourceURL)?.absoluteURL else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                guard let variantAttributes else { throw CocoaError(.fileReadCorruptFile) }
                variants.append((variantAttributes, absoluteURL))
            } else {
                result.append(line)
            }
        }
        if renditions.isEmpty {
            for (attributes, url) in variants { result.append(attributes); result.append(url.absoluteString) }
        }
        // Put the requested language first so a fresh player starts on it.
        let ordered = renditions.sorted { $0.streamIndex == selectedIndex && $1.streamIndex != selectedIndex }
        for rendition in ordered {
            for (attributes, variantURL) in variants {
                result.append(replacingAttribute("AUDIO", with: "\"finstream-audio-\(rendition.streamIndex)\"", in: attributes))
                guard var components = URLComponents(url: variantURL, resolvingAgainstBaseURL: false) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let selection = [
                    URLQueryItem(name: "AudioStreamIndex", value: String(rendition.streamIndex)),
                    URLQueryItem(name: "PlaySessionId", value: rendition.playSessionID)
                ]
                let keys: Set = ["audiostreamindex", "playsessionid"]
                components.queryItems = (components.queryItems ?? []).filter { !keys.contains($0.name.lowercased()) } + selection
                guard let url = components.url else { throw CocoaError(.fileReadCorruptFile) }
                result.append(url.absoluteString)
            }
        }
        return result.joined(separator: "\n") + "\n"
    }

    static func attributes(in line: String) -> [String: String] {
        Dictionary(attributeParts(in: line).compactMap { part in
            guard let separator = part.firstIndex(of: "=") else { return nil }
            return (String(part[..<separator]), String(part[part.index(after: separator)...]).trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
        }, uniquingKeysWith: { _, last in last })
    }

    static func subtitlePlaylists(in master: String, sourceURL: URL) -> [String: URL] {
        var playlists: [String: URL] = [:]
        for line in master.components(separatedBy: .newlines) where line.hasPrefix("#EXT-X-MEDIA:") {
            let values = attributes(in: line)
            guard values["TYPE"] == "SUBTITLES", let uri = values["URI"],
                  let url = URL(string: uri, relativeTo: sourceURL)?.absoluteURL,
                  url.pathExtension.lowercased() == "m3u8" else { continue }
            playlists["subtitles-\(playlists.count).m3u8"] = url
        }
        return playlists
    }

    private static func replacingAttribute(_ name: String, with value: String, in line: String) -> String {
        guard let colon = line.firstIndex(of: ":") else { return line }
        var parts = attributeParts(in: line).filter { !$0.hasPrefix(name + "=") }
        parts.append(name + "=" + value)
        return String(line[...colon]) + parts.joined(separator: ",")
    }

    private static func attributeParts(in line: String) -> [String] {
        guard let colon = line.firstIndex(of: ":") else { return [] }
        var inQuotes = false
        return line[line.index(after: colon)...].split { character in
            if character == "\"" { inQuotes.toggle() }
            return character == "," && !inQuotes
        }.map(String.init)
    }

    private static func quoted(_ value: String) -> String {
        value.replacing("\"", with: "′").replacing("\r", with: " ").replacing("\n", with: " ")
    }
}
