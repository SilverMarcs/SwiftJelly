//
//  SeerRequestItem.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

struct SeerRequestItem: Identifiable, Equatable {
    let request: SeerMediaRequest
    let item: BaseItemDto

    var id: Int { request.id }
}
