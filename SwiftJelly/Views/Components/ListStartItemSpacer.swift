//
//  ListStartItemSpacer.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 04.12.25.
//

import SwiftUI

struct ListStartItemSpacer: View {
    var body: some View {
#if !os(tvOS)
        Spacer()
#endif
    }
}

#Preview {
    ListStartItemSpacer()
}
