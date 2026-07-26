//
//  PairingMessage.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 26.07.26.
//

import Foundation

/// Messages exchanged over the encrypted `NWConnection` established through DeviceDiscoveryUI while
/// a signed-in device (the *sharer*, an iPhone/iPad) signs in a nearby Apple TV (the *receiver*).
///
/// Only server locations and short-lived Quick Connect codes ever travel over the wire — never an
/// access token. Each device ends up with its own server-minted token via the Quick Connect flow.
enum PairingMessage: Codable {
    /// A single server the sharer can offer to the receiver.
    struct ServerOffer: Codable, Identifiable, Hashable {
        let requestID: String
        let name: String
        let url: URL

        var id: String { requestID }
    }

    /// Sharer → receiver: the servers this device can share. The receiver (Apple TV) picks which
    /// ones to sign in to.
    case serverList([ServerOffer])

    /// Receiver → sharer: the Quick Connect code the receiver obtained for a chosen server, for the
    /// sharer to approve with its own credentials.
    case quickConnectCode(requestID: String, code: String)

    /// Receiver → sharer: the final outcome of signing in to a chosen server.
    case pairResult(requestID: String, success: Bool, message: String?)

    /// Sent by either side when the session is ending (finished or cancelled). Advisory only — the
    /// connection closing also signals the end.
    case done
}
