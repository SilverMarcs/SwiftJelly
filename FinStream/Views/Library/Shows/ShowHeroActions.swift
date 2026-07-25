import SwiftUI
import JellyfinAPI

struct ShowHeroActions: View {
    @Binding private var show: BaseItemDto
    let vm: ShowDetailViewModel

    /// When provided, the hero's focus scope uses this namespace so a parent can
    /// bias default focus onto the Play button.
    private let externalFocusNamespace: Namespace.ID?

    /// When provided, lets a parent programmatically move focus onto the Play
    /// button (e.g. when the hero scrolls back into view).
    private let playFocus: FocusState<Bool>.Binding?

    @Namespace private var actionButtonsNamespace

    #if os(tvOS)
    private var focusNamespace: Namespace.ID { externalFocusNamespace ?? actionButtonsNamespace }
    #endif

    init(show: Binding<BaseItemDto>, externalFocusNamespace: Namespace.ID? = nil, playFocus: FocusState<Bool>.Binding? = nil) {
        self._show = show
        self.vm = ShowDetailViewModel(item: show.wrappedValue)
        self.externalFocusNamespace = externalFocusNamespace
        self.playFocus = playFocus
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                ShowPlayButton(vm: vm)
#if os(tvOS)
                    .prefersDefaultFocus(in: focusNamespace)
                    .focused(optional: playFocus)
#endif
                #if os(tvOS)
                HeroInfoButton(item: show)
                #endif

                MarkPlayedButton(item: vm.selectedSeason)
                    .adaptiveDisabled(vm.playButtonDisabled)

                FavoriteButton(item: vm.show)
            }
        }
#if os(tvOS)
        .focusScope(focusNamespace)
#endif
        .environment(\.refresh, refreshAllAndSync)
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
    
    private func refreshAllAndSync() async {
        await vm.refreshAll()
        show = vm.show
    }
}
