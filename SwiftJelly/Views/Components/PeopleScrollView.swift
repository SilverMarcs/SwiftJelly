//
//  PeopleScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/07/2025.
//

import SwiftUI
import JellyfinAPI

struct PeopleScrollView: View {
    let people: [BaseItemPerson]?
    
    var body: some View {
        if let people = people {
            SectionContainer("Cast & Crew") {
                HorizontalShelf(spacing: spacing) {
                    ForEach(people, id: \.id) { person in
                        PersonView(person: Person(from: person))
                    }
                }
            } destination: {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(people, id: \.id) { person in
                            PersonView(person: Person(from: person))
                        }
                    }
                    .scenePadding()
                }
                .navigationTitle("Cast & Crew")
                .toolbarTitleDisplayMode(.inline)
            }
            #if os(tvOS)
            .frame(maxWidth: .infinity, alignment: .leading)
            #endif
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        24
        #else
        12
        #endif
    }
}
