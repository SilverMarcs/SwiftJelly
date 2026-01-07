import JellyfinAPI

extension ItemFields {
    static let MinimumFields: [ItemFields] = [
//        .mediaSources,
        .overview,
        .customRating,
        .genres,
//        .parentID,
//        .taglines,
        .people
//        .chapters
    ]
}

extension Array where Element == ItemFields {
    static var MinimumFields: Self {
        ItemFields.MinimumFields
    }
}
