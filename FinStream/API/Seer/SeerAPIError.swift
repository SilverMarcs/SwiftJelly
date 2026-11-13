//
//  SeerAPIError.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerAPIError: LocalizedError {
    case notConfigured
    case invalidURL
    case unauthorized
    case forbidden(message: String?)
    case missingSession
    case requestFailed(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "No Seer server is configured for this profile"
        case .invalidURL:
            "The Seer server URL is invalid"
        case .unauthorized:
            "Seer rejected the credentials. Sign in again in Settings."
        case .forbidden(let message):
            message ?? "You do not have permission to do this on Seer"
        case .missingSession:
            "Seer did not return a session. Check the server URL."
        case .requestFailed(let statusCode, let message):
            message ?? "Seer request failed with status \(statusCode)"
        }
    }
}
