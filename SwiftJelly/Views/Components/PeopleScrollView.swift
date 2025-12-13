//
//  PeopleScrollView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/07/2025.
//

import SwiftUI
import JellyfinAPI

struct PeopleScrollView: View {
    let people: [BaseItemPerson]
    
    var body: some View {
        SectionContainer("Cast & Crew") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(people, id: \.self) { person in
                        PersonView(person: person)
                    }
                }
                #if !os(tvOS)
                .scenePadding(.horizontal)
                #endif
            }
        }
        #if os(tvOS)
        .frame(maxWidth: .infinity, alignment: .leading)
        #else
        .padding(.top)
        #endif
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        24
        #else
        12
        #endif
    }
}
