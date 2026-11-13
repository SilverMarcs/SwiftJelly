//
//  BaseItemDto+Seer.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

extension BaseItemDto {
    var isSeerItem: Bool {
        serverID == SeerMediaReference.serverID
    }

    var seerReference: SeerMediaReference? {
        guard isSeerItem, let id else { return nil }
        return SeerMediaReference(itemID: id)
    }
}
