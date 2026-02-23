import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PersonView: View {
    let person: Person
    
    var body: some View {
        NavigationLink(value: person) {
            LabelStack {
                if let url = ImageURLProvider.personImageURL(for: person.id) {
                    CachedAsyncImage(url: url, targetSize: Int(imageSize * 2)) {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .background(.background.secondary)
                    .overlay {
                        Circle()
                            .strokeBorder(.tertiary, lineWidth: 1)
                    }
                    #if !os(macOS)
                    .hoverEffect(.highlight)
                    #endif
                    #if !os(tvOS)
                    .clipShape(.circle)
                    .clipped()
                    #endif
                }
                
                Text(person.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let subtitle = person.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
     
                }
            }
        }
        .frame(maxWidth: imageSize)
        .buttonBorderShape(.circle)
        .adaptiveButtonStyle()
    }
    
    private var imageSize: CGFloat {
        #if os(tvOS)
        200
        #else
        100
        #endif
    }
}


#Preview {
    PersonView(person: Person(id: "", name: "Test", subtitle: "Actor"))
}
