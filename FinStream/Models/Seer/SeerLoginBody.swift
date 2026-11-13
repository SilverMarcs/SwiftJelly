//
//  SeerLoginBody.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerLoginBody: Encodable {
    let username: String?
    let email: String?
    let password: String

    init(method: SeerAuthMethod, username: String, password: String) {
        switch method {
        case .jellyfin:
            self.username = username
            self.email = nil
        case .local:
            self.username = nil
            self.email = username
        }
        self.password = password
    }
}
