//
//  JFAPI+Auth.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Authenticates a user with the given credentials and server, returning authentication data on success
    /// - Parameters:
    ///   - username: The username to authenticate
    ///   - password: The password to authenticate
    ///   - server: The server to authenticate against
    /// - Returns: AuthenticationResult if authentication is successful
    static func authenticateUser(username: String, password: String, server: Server) async throws -> AuthenticationResult {
        let configuration = JellyfinClient.Configuration(
            url: server.url,
            client: "SwiftJelly",
            deviceName: "SwiftJelly",
            deviceID: UUID().uuidString,
            version: "1.0"
        )
        let client = JellyfinClient(configuration: configuration)
        let authRequest = Paths.authenticateUserByName(
            AuthenticateUserByName(
                pw: password.isEmpty ? nil : password,
                username: username
            )
        )
        let response = try await client.send(authRequest)
        let authResult = response.value
        guard let accessToken = authResult.accessToken,
              let userData = authResult.user else {
            throw JFAPIError.loginFailed
        }
        return AuthenticationResult(
            username: username,
            accessToken: accessToken,
            jellyfinUserID: userData.id ?? UUID().uuidString
        )
    }

    /// Result type for authentication
    struct AuthenticationResult {
        let username: String
        let accessToken: String
        let jellyfinUserID: String
    }
}
