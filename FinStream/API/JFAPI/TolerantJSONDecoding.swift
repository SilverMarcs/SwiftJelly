import Foundation
import JellyfinAPI
import OSLog

private protocol OptionalDecoding {}
extension Optional: OptionalDecoding {}

/// Jellyfin keeps adding values to the string enums in its API (e.g. `VideoRangeType.DOVIWithHDR10Plus`),
/// and the SDK decodes them strictly, so one unknown value fails the whole response. Decoding is retried
/// once with unknown enum values replaced by a fallback or removed.
nonisolated enum TolerantJSONDecoding {
    private static let logger = Logger(subsystem: "com.SilverMarcs.SwiftJelly", category: "Decoding")

    /// Mirrors Get's `APIClient.send`, including decoding off the calling actor.
    static func decode<T: Decodable>(_ data: Data, as type: T.Type = T.self) async throws -> T {
        if data.isEmpty, T.self is OptionalDecoding.Type {
            return Optional<Decodable>.none as! T
        }
        if T.self == Data.self {
            return data as! T
        }
        if T.self == String.self {
            guard let string = String(data: data, encoding: .utf8) else {
                throw URLError(.badServerResponse)
            }
            return string as! T
        }

        let decoder = makeDecoder()
        do {
            return try await decodeDetached(T.self, from: data, using: decoder)
        } catch let error as DecodingError {
            guard let sanitized = sanitize(data, label: "\(T.self)") else { throw error }
            return try await decodeDetached(T.self, from: sanitized, using: decoder)
        }
    }

    /// The SDK models aren't `Sendable`; the value is created inside the task and handed over once.
    private struct DecodedBox<Value>: @unchecked Sendable {
        let value: Value
    }

    private static func decodeDetached<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        using decoder: JSONDecoder
    ) async throws -> T {
        let box = try await Task.detached {
            DecodedBox(value: try decoder.decode(T.self, from: data))
        }.value
        return box.value
    }

    /// Matches `JellyfinClient`'s decoder; the SDK's `OpenISO8601DateFormatter` initializer is internal.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoFormatterWithFractionalSeconds.date(from: string) {
                return date
            }
            if let date = isoFormatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(string)"
            )
        }
        return decoder
    }

    private static func makeISOFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = dateFormat
        return formatter
    }

    private static let isoFormatterWithFractionalSeconds = makeISOFormatter(
        dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    )

    private static let isoFormatter = makeISOFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")

    private struct EnumField {
        let allowed: Set<String>
        /// When nil, the key is removed so the optional property decodes as nil.
        let fallback: String?

        init<T: RawRepresentable & CaseIterable>(_ type: T.Type, fallback: String? = nil) where T.RawValue == String {
            self.allowed = Set(T.allCases.map(\.rawValue))
            self.fallback = fallback
        }
    }

    /// Only keys that map to one enum across all payloads; generic keys like `Type` are left out.
    private static let enumFields: [String: EnumField] = [
        "VideoRange": EnumField(VideoRange.self, fallback: VideoRange.unknown.rawValue),
        "VideoRangeType": EnumField(VideoRangeType.self, fallback: VideoRangeType.unknown.rawValue),
        "AudioSpatialFormat": EnumField(AudioSpatialFormat.self, fallback: AudioSpatialFormat.none.rawValue),
        "Protocol": EnumField(MediaProtocol.self),
        "EncoderProtocol": EnumField(MediaProtocol.self),
        "TranscodingSubProtocol": EnumField(MediaStreamProtocol.self),
        "Timestamp": EnumField(TransportStreamTimestamp.self),
        "VideoType": EnumField(VideoType.self),
        "IsoType": EnumField(IsoType.self),
        "Video3DFormat": EnumField(Video3DFormat.self),
        "DeliveryMethod": EnumField(SubtitleDeliveryMethod.self),
        "ErrorCode": EnumField(PlaybackErrorCode.self)
    ]

    /// Returns nil when nothing needed changing.
    static func sanitize(_ data: Data, label: String) -> Data? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

        var substitutions: [String] = []
        let sanitized = rewrite(json, path: "", substitutions: &substitutions)

        guard !substitutions.isEmpty else { return nil }

        for substitution in substitutions {
            logger.error("[\(label, privacy: .public)] unknown API enum value: \(substitution, privacy: .public)")
        }

        return try? JSONSerialization.data(withJSONObject: sanitized)
    }

    private static func rewrite(_ value: Any, path: String, substitutions: inout [String]) -> Any {
        if let array = value as? [Any] {
            return array.enumerated().map { index, element in
                rewrite(element, path: "\(path)[\(index)]", substitutions: &substitutions)
            }
        }

        guard var object = value as? [String: Any] else { return value }

        for (key, child) in object {
            let childPath = path.isEmpty ? key : "\(path).\(key)"

            if let field = enumFields[key], let rawValue = child as? String {
                guard !field.allowed.contains(rawValue) else { continue }
                if let fallback = field.fallback {
                    object[key] = fallback
                    substitutions.append("\(childPath)=\(rawValue) → \(fallback)")
                } else {
                    object.removeValue(forKey: key)
                    substitutions.append("\(childPath)=\(rawValue) → dropped")
                }
                continue
            }

            object[key] = rewrite(child, path: childPath, substitutions: &substitutions)
        }

        return object
    }
}
