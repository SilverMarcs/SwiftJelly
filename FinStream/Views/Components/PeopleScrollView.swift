//
//  PeopleScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/07/2025.
//
// We use ViewListItem here to automatically generate a new ID for each person, we don't care about
// placeholder items, since persons should always not be empty.
// The problem with just having [BaseItemPerson] is that sometimes one person may occur multiple
// times (e.g. as actor and director), but still has the same ID, this breaks SwiftUI List.
//

import SwiftUI
import JellyfinAPI

struct PeopleScrollView: View {
    var peopleViewCollection: [ViewListItem<BaseItemPerson>] = []
    
    init(people: [BaseItemPerson]) {
        peopleViewCollection.update(with: people)
    }
    
    var body: some View {
        SectionContainer {
            HorizontalShelf(spacing: spacing) {
                ForEach(peopleViewCollection, id: \.id) { person in
                    if let person = person.base {
                        PersonView(person: Person(from: person))
                    }
                }
            }
        } header: {
            Text("Cast & Crew")
        }
        #if os(tvOS)
        .frame(maxWidth: .infinity, alignment: .leading)
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        12
        #endif
    }
}
