//
//  SeerLoginViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

@MainActor
@Observable
final class SeerLoginViewModel {
    let profile: Server

    var urlString: String
    var authMethod: SeerAuthMethod
    var username: String
    var password = ""
    private(set) var isConnecting = false
    var errorMessage: String?

    init(profile: Server, suggestedURL: URL?) {
        self.profile = profile
        let account = profile.seer
        urlString = (account?.url ?? suggestedURL)?.absoluteString ?? ""
        authMethod = account?.authMethod ?? .jellyfin
        username = account?.username ?? profile.username ?? ""
    }

    var canConnect: Bool {
        !urlString.isEmpty && !username.isEmpty && !password.isEmpty && !isConnecting
    }

    func connect() async -> Bool {
        guard let url = normalizedURL else {
            errorMessage = SeerAPIError.invalidURL.localizedDescription
            return false
        }

        isConnecting = true
        defer { isConnecting = false }

        do {
            try await SeerAPI.connect(profile: profile, url: url, method: authMethod, username: username, password: password)
            password = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private var normalizedURL: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.host() != nil else { return nil }
        return url
    }
}
