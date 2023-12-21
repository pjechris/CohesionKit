/// A type wrapping one or more Identifiable types.
/// You should rarely need to use this type. However it can happens to have a non Aggregate object containing Identifiable
/// objects to group them (for consistency or naming). This is especially true with enum cases.
public protocol EntityWrapper {
    /// Entities contained by all cases relative to the parent container
    /// - Returns: entities contained in the wrapper
    ////
    /// Example:
    //// ```swift
    /// enum MyEnum: EntityWrapper {
    ///     case a(A)
    ///     case b(B)
    ///
    ///    // note: you would also need to create computed getter/setter for a and b
    ///    func wrappedEntitiesKeyPaths<Root>(relativeTo root: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>] {
    ///     [.init(root.appending(\.a)), .init(root.appending(\.b))]
    ///    }
    /// }
    /// ```
    func wrappedEntitiesKeyPaths<Root>(relativeTo parent: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>]
}