import SwiftUI
import JellyfinAPI
import SwiftMediaViewer

struct PersonView: View {
    let person: Person
    
    var body: some View {
        NavigationLink(value: NavigationRoute.person(person)) {
            PersonLabel(
                imageURL: ImageURLProvider.personImageURL(for: person.id),
                name: person.name,
                subtitle: person.subtitle
            )
        }
        .frame(maxWidth: PersonLabel.imageSize)
        .buttonBorderShape(.circle)
        .adaptiveButtonStyle()
    }
}


#Preview {
    PersonView(person: Person(id: "", name: "Test", subtitle: "Actor"))
}
