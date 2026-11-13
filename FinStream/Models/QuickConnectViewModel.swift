//
//  QuickConnectViewModel.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import Foundation
import JellyfinAPI

@MainActor
@Observable
final class QuickConnectViewModel {
    enum Phase: Equatable {
        case connecting
        case awaitingApproval(code: String)
        case authenticating
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
        client = JFAPI.makeQuickConnectClient(for: server)
    }

    func start(onSuccess: @escaping (Server) -> Void) {
        flowTask?.cancel()
        phase = .connecting

        flowTask = Task {
            do {
                let (secret, code) = try await JFAPI.initiateQuickConnect(client: client)
                phase = .awaitingApproval(code: code)

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

                phase = .failed("Quick Connect timed out. Please try again.")
            } catch is CancellationError {
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        flowTask?.cancel()
        flowTask = nil
    }
}
