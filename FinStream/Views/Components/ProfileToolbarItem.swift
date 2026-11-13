//
//  ProfileToolbarItem.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 13.11.26.
//

#if os(iOS)
import SwiftUI

/// The profile menu as a trailing toolbar item.
///
/// SwiftUI places items from an outer `.toolbar` before those of inner views, so this
/// item has to be declared in the same toolbar builder as a screen's own trailing items,
/// after them, to reliably end up at the trailing edge.
struct ProfileToolbarItem: ToolbarContent {
    /// Opens Settings; `nil` hides the item.
    let showSettings: (() -> Void)?

    var body: some ToolbarContent {
        if let showSettings {
            ToolbarItem(placement: .primaryAction) {
                ProfileToolbarMenu(showSettings: showSettings)
            }
        }
    }
}

/// Adds the profile menu to screens that have no other trailing toolbar items.
private struct ProfileToolbarModifier: ViewModifier {
    @Environment(\.profileToolbarSettingsAction) private var profileToolbarSettingsAction
    @Environment(\.isPresented) private var isPresented

    func body(content: Content) -> some View {
        content
            .toolbar {
                // Only tab root screens show the profile, not screens pushed onto them.
                ProfileToolbarItem(showSettings: isPresented ? nil : profileToolbarSettingsAction)
            }
    }
}

extension View {
    func profileToolbarItem() -> some View {
        modifier(ProfileToolbarModifier())
    }
}
#endif
