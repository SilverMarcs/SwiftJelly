import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PersonView: View {
    let person: BaseItemPerson
    
    #if os(tvOS)
    private let imageSize: CGFloat = 220
    #else
    private let imageSize: CGFloat = 100
    #endif
    
    var body: some View {
        VStack {
            NavigationLink {
                PersonMediaView(person: person)
            } label: {
                VStack {
                    ZStack {
                        Color.gray.opacity(0.3)
                            .frame(width: imageSize, height: imageSize)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }

                        if let url = ImageURLProvider.personImageURL(for: person) {
                            CachedAsyncImage(url: url, targetSize: Int(imageSize * 2))
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageSize, height: imageSize)
                        }
                    }
                    #if !os(macOS)
                    .hoverEffect(.highlight)
                    #endif
                    
                    #if !os(tvOS)
                    .clipShape(Circle())
                    .clipped()
                    #endif
                    
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
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    PersonView(person: BaseItemPerson.init(id: "ea2acead101e71b7dc93c5bbaf0a8cdc", name: "Some actor"))
}
