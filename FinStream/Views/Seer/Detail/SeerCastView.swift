//
//  SeerCastView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import SwiftUI

struct SeerCastView: View {
    let cast: [SeerCreditPerson]

    var body: some View {
        SectionContainer(isVisible: !cast.isEmpty) {
            HorizontalShelf(spacing: spacing) {
                ForEach(cast.enumerated(), id: \.offset) { _, person in
                    PersonLabel(
                        imageURL: SeerImageURL.url(path: person.profilePath, size: .profile),
                        name: person.name,
                        subtitle: person.character
                    )
                    .frame(maxWidth: PersonLabel.imageSize)
                    #if os(tvOS)
                    .focusable()
                    #endif
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
