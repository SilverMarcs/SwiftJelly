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
    /// Builds an unauthenticated client for a server, suitable for the Quick Connect flow.
    ///
    /// The same client instance (and therefore the same device ID) must be reused across the
    /// initiate, poll and authenticate steps, otherwise the server will not recognise the
    /// authorized request.
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

    /// Initiates a Quick Connect request.
    /// - Returns: The secret used for polling and the user-facing code to display.
    static func initiateQuickConnect(client: JellyfinClient) async throws -> (secret: String, code: String) {
        let response = try await client.send(Paths.initiate)
        guard let secret = response.value.secret,
              let code = response.value.code else {
            throw JFAPIError.quickConnectFailed
        }
        return (secret, code)
    }

    /// Checks whether a Quick Connect request has been authorized by the user yet.
    static func isQuickConnectAuthorized(secret: String, client: JellyfinClient) async throws -> Bool {
        let response = try await client.send(Paths.connect(secret: secret))
        return response.value.isAuthenticated ?? false
    }

    /// Exchanges an authorized Quick Connect secret for authentication data.
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

    /// Authorizes a pending Quick Connect request that was initiated on another device, using the
    /// currently signed-in user. This is the "pair a new device" direction of the flow: the other
    /// device displays a code, and this authenticated device approves it.
    /// - Parameter code: The code shown on the device that is waiting to be signed in.
    /// - Returns: `true` when the server accepted the code and authorized the pending request.
    static func authorizeQuickConnect(code: String) async throws -> Bool {
        let context = try getAPIContext()
        let request = Request<Bool>(
            path: "/QuickConnect/Authorize",
            method: "POST",
            query: [("code", code), ("userId", context.userID)],
            id: "AuthorizeQuickConnect"
        )
        let response = try await context.client.send(request)
        return response.value
    }
}
