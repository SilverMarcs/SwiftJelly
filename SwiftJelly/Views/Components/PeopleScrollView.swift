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
        VStack(alignment: .leading) {
            Text("Cast & Crew")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(people, id: \.self) { person in
                        PersonView(person: person)
                            .frame(width: 80)
                    }
                }
            }
        }
    }
}
