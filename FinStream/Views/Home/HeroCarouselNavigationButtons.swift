#if os(tvOS)
import SwiftUI

struct HeroCarouselNavigationButtons: View {
    let focusedButton: FocusState<HeroCarouselNavigationButton?>.Binding
    let showsPrevious: Bool
    let showsNext: Bool
    let showPrevious: () -> Void
    let showNext: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 15) {
            HStack(spacing: 15) {
                if showsPrevious {
                    Button(action: showPrevious) {
                        Label("Previous Slide", systemImage: "chevron.left")
                            .labelStyle(.iconOnly)
                            .heroActionIcon()
                    }
                    .focused(focusedButton, equals: .previous)
                }

                if showsNext {
                    Button(action: showNext) {
                        Label("Next Slide", systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                            .heroActionIcon()
                    }
                    .focused(focusedButton, equals: .next)
                }
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .tint(.primary)
    }
}
#endif
