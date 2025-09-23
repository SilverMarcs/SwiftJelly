import JellyfinAPI

extension ItemFields {
    static let MinimumFields: [ItemFields] = [
        .mediaSources,
        .overview,
        .parentID,
        .taglines,
        .people,
    ]
}

extension Array where Element == ItemFields {
    static var MinimumFields: Self {
        ItemFields.MinimumFields
    }
}
