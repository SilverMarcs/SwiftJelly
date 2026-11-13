//
//  SeerAPI+Auth.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

extension SeerAPI {
    static func signIn(url: URL, method: SeerAuthMethod, username: String, password: String) async throws -> SeerAccount {
        let endpoint = try SeerEndpoint(
            path: method.endpoint,
            body: SeerLoginBody(method: method, username: username, password: password)
        )
        let (data, response) = try await SeerHTTPClient.data(for: endpoint.urlRequest(baseURL: url, cookie: nil))

        guard let cookie = SeerHTTPClient.sessionCookie(from: response) else {
            throw SeerAPIError.missingSession
        }
        let user = try JSONDecoder().decode(SeerUser.self, from: data)

        return SeerAccount(
            url: url,
            authMethod: method,
            username: username,
            sessionCookie: cookie,
            userID: user.id,
            displayName: user.displayName ?? user.email ?? username
        )
    }

    static func connect(profile: Server, url: URL, method: SeerAuthMethod, username: String, password: String) async throws {
        let account = try await signIn(url: url, method: method, username: username, password: password)
        SeerCredentialStore.save(password: password, for: profile.id)

        guard var updatedProfile = dataManager.servers.first(where: { $0.id == profile.id }) else { return }
        updatedProfile.seer = account
        dataManager.updateServer(updatedProfile)
    }

    static func disconnect(profile: Server) {
        SeerCredentialStore.deletePassword(for: profile.id)

        guard var updatedProfile = dataManager.servers.first(where: { $0.id == profile.id }) else { return }
        updatedProfile.seer = nil
        dataManager.updateServer(updatedProfile)
    }
}
