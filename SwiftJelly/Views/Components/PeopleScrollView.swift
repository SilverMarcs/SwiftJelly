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
    
    #if os(tvOS)
    private let personWidth: CGFloat = 130
    private let spacing: CGFloat = 24
    #else
    private let personWidth: CGFloat = 80
    private let spacing: CGFloat = 12
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cast & Crew")
                #if os(tvOS)
                .font(.title3)
                .fontWeight(.bold)
                #else
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
                #endif
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(people, id: \.self) { person in
                        PersonView(person: person)
                    }
                }
            }
            #if os(tvOS)
            .scrollClipDisabled()
            #endif
        }
    }
}
