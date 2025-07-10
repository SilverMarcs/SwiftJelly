import SwiftUI
import JellyfinAPI

struct UniversalMediaPlayerView: View {
    let item: BaseItemDto
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    var body: some View {
        if AVPlayerSupportChecker.isSupported(item: item) {
            AVMediaPlayerView(item: item)
        } else {
//            VLCPlayerView(item: item)
            Text("Playing MKV is currently not supported")
        }
    }
}
