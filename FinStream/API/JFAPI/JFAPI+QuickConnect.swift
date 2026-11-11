//
//  JFAPI+QuickConnect.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Reuse the returned client for initiate, poll and authenticate; the server ties the request to its device ID.
    static func makeQuickConnectClient(for server: Server) -> JellyfinClient {
        let configuration = JellyfinClient.Configuration(
            url: server.url,
            client: clientName,
            deviceName: clientName,
            deviceID: UUID().uuidString,
            version: "1.0"
        )
        return JellyfinClient(configuration: configuration)
    }

    static func initiateQuickConnect(client: JellyfinClient) async throws -> (secret: String, code: String) {
        let response = try await client.send(Paths.initiate)
        guard let secret = response.value.secret,
              let code = response.value.code else {
            throw JFAPIError.quickConnectFailed
        }
        return (secret, code)
    }

    static func isQuickConnectAuthorized(secret: String, client: JellyfinClient) async throws -> Bool {
        let response = try await client.send(Paths.connect(secret: secret))
        return response.value.isAuthenticated ?? false
    }

    static func authenticateWithQuickConnect(secret: String, client: JellyfinClient) async throws -> AuthenticationResult {
        let response = try await client.send(Paths.authenticateWithQuickConnect(QuickConnectDto(secret: secret)))
        let authResult = response.value
        guard let accessToken = authResult.accessToken,
              let userData = authResult.user else {
            throw JFAPIError.loginFailed
        }
        return AuthenticationResult(
            username: userData.name ?? "",
            accessToken: accessToken,
            jellyfinUserID: userData.id ?? UUID().uuidString
        )
    }

    /// Approves a code shown on another device using the signed-in user.
    static func authorizeQuickConnect(code: String) async throws -> Bool {
        let context = try getAPIContext()
        let request = Request<Bool>(
            path: "/QuickConnect/Authorize",
            method: "POST",
            query: [("code", code), ("userId", context.userID)],
            id: "AuthorizeQuickConnect"
        )
        return try await send(request, context: context)
    }
}
