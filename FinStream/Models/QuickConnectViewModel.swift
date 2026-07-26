//
//  QuickConnectViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import Foundation
import JellyfinAPI

/// Drives the Jellyfin Quick Connect authorization flow: requesting a code, polling until the
/// user approves it on another device, and finally exchanging the secret for authentication data.
@MainActor
@Observable
final class QuickConnectViewModel {
    enum Phase: Equatable {
        /// Requesting a Quick Connect code from the server.
        case connecting
        /// Waiting for the user to approve the displayed code on another device.
        case awaitingApproval(code: String)
        /// Exchanging the approved secret for an access token.
        case authenticating
        /// The flow failed with a user-facing message.
        case failed(String)
    }

    private(set) var phase: Phase = .connecting

    private let server: Server
    private let client: JellyfinClient
    private var flowTask: Task<Void, Never>?

    private let pollIntervalSeconds: UInt64 = 5
    private let maxPolls = 200

    init(server: Server) {
        self.server = server
        self.client = JFAPI.makeQuickConnectClient(for: server)
    }

    /// Starts (or restarts) the Quick Connect flow.
    /// - Parameters:
    ///   - onCode: Called with the user-facing code as soon as it is obtained. Used by the nearby
    ///     pairing flow to relay the code to the approving device instead of displaying it.
    ///   - onFailure: Called with a user-facing message if the flow fails or times out.
    ///   - onSuccess: Called with an authenticated server once the request has been approved.
    func start(
        onCode: ((String) -> Void)? = nil,
        onFailure: ((String) -> Void)? = nil,
        onSuccess: @escaping (Server) -> Void
    ) {
        flowTask?.cancel()
        phase = .connecting

        flowTask = Task {
            do {
                let (secret, code) = try await JFAPI.initiateQuickConnect(client: client)
                phase = .awaitingApproval(code: code)
                onCode?(code)

                for _ in 0 ..< maxPolls {
                    try Task.checkCancellation()

                    if try await JFAPI.isQuickConnectAuthorized(secret: secret, client: client) {
                        phase = .authenticating
                        let auth = try await JFAPI.authenticateWithQuickConnect(secret: secret, client: client)

                        var authenticatedServer = server
                        authenticatedServer.username = auth.username
                        authenticatedServer.accessToken = auth.accessToken
                        authenticatedServer.jellyfinUserID = auth.jellyfinUserID
                        onSuccess(authenticatedServer)
                        return
                    }

                    try await Task.sleep(nanoseconds: pollIntervalSeconds * 1_000_000_000)
                }

                let message = "Quick Connect timed out. Please try again."
                phase = .failed(message)
                onFailure?(message)
            } catch is CancellationError {
                // The flow was cancelled intentionally, nothing to report.
            } catch {
                phase = .failed(error.localizedDescription)
                onFailure?(error.localizedDescription)
            }
        }
    }

    /// Cancels any in-flight Quick Connect work, e.g. when the user dismisses the view.
    func cancel() {
        flowTask?.cancel()
        flowTask = nil
    }
}
