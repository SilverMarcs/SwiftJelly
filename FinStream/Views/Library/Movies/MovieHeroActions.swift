import SwiftUI
import JellyfinAPI

struct MovieHeroActions: View {
    @Binding var movie: BaseItemDto

    /// When provided, the hero's focus scope uses this namespace so a parent can
    /// bias default focus onto the Play button.
    var externalFocusNamespace: Namespace.ID? = nil

    /// When provided, lets a parent programmatically move focus onto the Play
    /// button (e.g. when the hero scrolls back into view).
    var playFocus: FocusState<Bool>.Binding? = nil

    @Namespace private var actionButtonsNamespace

    #if os(tvOS)
    private var focusNamespace: Namespace.ID { externalFocusNamespace ?? actionButtonsNamespace }
    #endif

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                MoviePlayButton(item: movie)
#if os(tvOS)
                    .prefersDefaultFocus(in: focusNamespace)
                    .focused(optional: playFocus)
#endif

                #if os(tvOS)
                HeroInfoButton(item: movie)
                #endif

                MarkPlayedButton(item: movie)

                FavoriteButton(item: movie)
            }
        }
        .redacted(reason: movie.name?.isEmpty == false ? [] : .placeholder)
#if os(tvOS)
        .focusScope(focusNamespace)
#endif
        .environment(\.refresh, refresh)
    }

    private func refresh() async {
        guard let id = movie.id, !id.isEmpty else { return }
        do {
            movie = try await JFAPI.loadItem(by: id)
        } catch {
            print("Error refreshing movie: \(error)")
        }
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        15
        #elseif os(macOS)
        8
        #else
        6
        #endif
    }
}
