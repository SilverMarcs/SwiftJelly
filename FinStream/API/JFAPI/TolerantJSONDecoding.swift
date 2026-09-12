//
//  TolerantJSONDecoding.swift
//  SwiftJelly
//
//  Jellyfin keeps adding values to the string enums in its API (for example
//  `VideoRangeType.DOVIWithHDR10Plus` for Dolby Vision Profile 8 with an
//  HDR10+ base layer). The generated SDK models decode those enums strictly,
//  so a single unknown value makes an entire response fail to decode — which
//  looks like a blank player or a missing item rather than a parse error.
//
//  These helpers retry a failed decode once with the unrecognized enum values
//  rewritten to a safe fallback (or removed, leaving the optional property
//  nil). Every substitution is logged so genuine schema drift stays visible
//  instead of being silently swallowed.
//

import Foundation
import JellyfinAPI

nonisolated enum TolerantJSONDecoding {

    /// Mirrors the decoder `JellyfinClient` configures for its own requests.
    /// The SDK's `OpenISO8601DateFormatter` has an internal initializer, so the
    /// same two formats (with and without fractional seconds) are rebuilt here.
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
        /// Value to substitute when the server sends something unknown. When
        /// nil the key is removed instead, so the optional property decodes as
        /// nil rather than failing.
        let fallback: String?

        init<T: RawRepresentable & CaseIterable>(_ type: T.Type, fallback: String? = nil) where T.RawValue == String {
            self.allowed = Set(T.allCases.map(\.rawValue))
            self.fallback = fallback
        }
    }

    /// JSON keys whose values are strict string enums in the SDK. Only keys
    /// that unambiguously map to one enum across Jellyfin payloads are listed;
    /// generic keys like `Type` are deliberately left out.
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

    /// Rewrites unrecognized enum values in `data`. Returns nil when nothing
    /// needed changing, so the caller can rethrow the original error.
    static func sanitize(_ data: Data, label: String) -> Data? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

        var substitutions: [String] = []
        let sanitized = rewrite(json, path: "", substitutions: &substitutions)

        guard !substitutions.isEmpty else { return nil }

        for substitution in substitutions {
            PlaybackLog.error("[\(label)] unknown API enum value — \(substitution)")
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
