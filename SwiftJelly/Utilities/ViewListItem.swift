//
//  Placeholder.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 08.02.26.
//

import JellyfinAPI
import Foundation

public struct ViewListItem<T: Equatable>: Identifiable, Equatable {
    public var id: UUID
    public var base: T?
    
    public static func == (lhs: ViewListItem<T>, rhs: ViewListItem<T>) -> Bool {
        lhs.id == rhs.id && lhs.base == rhs.base
    }
}

extension Array {
    mutating func update<T: Equatable>(with newDtos: [T]) where Element == ViewListItem<T> {
        // Remove extra items if the new list is smaller
        if newDtos.count < self.count {
            self.removeLast(self.count - newDtos.count)
        }

        for (index, dto) in newDtos.enumerated() {
            if index < self.count {
                // Update the existing wrapper's base data
                // This keeps the ID the same, preserving SwiftUI focus (very important for tvOS)
                self[index].base = dto
            } else {
                // Add new items if the new list is longer
                self.append(ViewListItem(id: UUID(), base: dto))
            }
        }
    }
}

public func withPlaceholderItems<T: Equatable>(size: Int) -> [ViewListItem<T>] {
    (0..<size).map { _ in ViewListItem<T>(id: UUID(), base: nil)}
}
