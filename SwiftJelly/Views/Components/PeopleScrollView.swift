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
        VStack(alignment: .leading, spacing: 16) {
            Text("Cast & Crew")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top)
                .scenePadding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(people, id: \.self) { person in
                        PersonView(person: person)
                    }
                }
                .scenePadding(.horizontal)
            }
            #if os(tvOS)
            .scrollClipDisabled()
            #endif
        }
    }
    
    private var personWidth: CGFloat {
        #if os(tvOS)
        130
        #else
        80
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
