//
//  SeerAPI.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerAPI {
    static let dataManager: DataManager = .shared

    static var isConfigured: Bool {
        dataManager.server?.seer?.isAuthenticated == true
    }

    static func send<Response: Decodable>(_ endpoint: SeerEndpoint) async throws -> Response {
        guard let profile = dataManager.server, let account = profile.seer, account.isAuthenticated else {
            throw SeerAPIError.notConfigured
        }

        do {
            return try await perform(endpoint, account: account)
        } catch SeerAPIError.unauthorized, SeerAPIError.forbidden {
            let refreshedAccount = try await reauthenticate(profileID: profile.id, account: account)
            return try await perform(endpoint, account: refreshedAccount)
        }
    }

    private static func perform<Response: Decodable>(_ endpoint: SeerEndpoint, account: SeerAccount) async throws -> Response {
        let request = try endpoint.urlRequest(baseURL: account.url, cookie: account.sessionCookie)
        let (data, _) = try await SeerHTTPClient.data(for: request)
        if Response.self == SeerEmptyResponse.self, let empty = SeerEmptyResponse() as? Response {
            return empty
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func reauthenticate(profileID: String, account: SeerAccount) async throws -> SeerAccount {
        guard let password = SeerCredentialStore.password(for: profileID) else {
            throw SeerAPIError.unauthorized
        }

        let refreshedAccount = try await signIn(
            url: account.url,
            method: account.authMethod,
            username: account.username,
            password: password
        )

        if var profile = dataManager.servers.first(where: { $0.id == profileID }) {
            profile.seer = refreshedAccount
            dataManager.updateServer(profile)
        }
        return refreshedAccount
    }
}
