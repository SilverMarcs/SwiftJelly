import SwiftUI


extension View {
    /// Normalizes the size of an icon used inside a circular hero action button
    /// (info / favorite / mark-played) so all three buttons render at an
    /// identical width & height regardless of which SF Symbol they use.
    @ViewBuilder
    func heroActionIcon() -> some View {
        #if os(tvOS)
        self.frame(width: 35, height: 35)
        #elseif os(macOS)
        self.frame(width: 15, height: 15)
        #else
        self.frame(width: 20, height: 20)
        #endif
    }
}
