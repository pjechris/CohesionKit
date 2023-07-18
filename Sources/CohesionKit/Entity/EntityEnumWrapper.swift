/// a type wrapping one or more Identifiable types. As the name indicates you should use this type **only** on enums:
/// this is the easiest way to extract types they are containing. If you facing a non enum case where you feel you need
/// this type: rethink about it ;)
public protocol EntityEnumWrapper {
    /// Entities contained by all cases relative to the parent container
    /// - Returns: entities contained in the enum
    ////
    /// Example:
    //// ```swift
    /// enum MyEnum: EntityEnumWrapper {
    ///     case a(A)
    ///     case b(B)
    ///
    ///    // you would also need to create computed getter/setter for a and b
    ///    func wrappedEntitiesKeyPaths<Root>(relativeTo root: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>] {
    ///     [.init(root.appending(\.a)), .init(root.appending(\.b))]
    ///    }
    /// }
    /// ```
    func wrappedEntitiesKeyPaths<Root>(relativeTo parent: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>]
}