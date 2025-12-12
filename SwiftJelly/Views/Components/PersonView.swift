import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PersonView: View {
    let person: BaseItemPerson
    
    var body: some View {
        NavigationLink(value: person) {
            VStack {
                if let url = ImageURLProvider.personImageURL(for: person) {
                    CachedAsyncImage(url: url, targetSize: Int(imageSize * 2))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        #if !os(macOS)
                        .hoverEffect(.highlight)
                        #endif
                        #if !os(tvOS)
                        .clipShape(.circle)
                        .clipped()
                        #endif
                }
                
                if let name = person.name {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                if let role = person.role, !role.isEmpty {
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: imageSize)   
        }
        .foregroundStyle(.primary)
        .buttonBorderShape(.circle)
        #if os(tvOS)
        .buttonStyle(.borderless)
        #else
        .buttonStyle(.plain)
        #endif
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
    PersonView(person: BaseItemPerson.init(id: "ea2acead101e71b7dc93c5bbaf0a8cdc", name: "Some actor"))
}
