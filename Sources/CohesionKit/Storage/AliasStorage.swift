/// Keep a strong reference on each aliased node
typealias AliasStorage = [AnyHashable: AnyRef]

extension AliasStorage {
    subscript<T>(key: AliasKey<T>) -> Ref<EntityNode<T>?> {
        mutating get {
            if let store = self[AnyHashable(key)] as? Ref<EntityNode<T>?> {
                return store
            }
            
            let store: Ref<EntityNode<T>?> = Ref(value: nil)
            self[AnyHashable(key)] = store
            
            return store
            
        }
    }
    
    subscript<C: Collection>(key: AliasKey<C>) -> Ref<[EntityNode<C.Element>]?> {
        mutating get {
            if let store = self[AnyHashable(key)] as? Ref<[EntityNode<C.Element>]?> {
                return store
            }
            
            let store: Ref<[EntityNode<C.Element>]?> = Ref(value: nil)
            self[AnyHashable(key)] = store
            
            return store
            
        }
    }
    
    mutating func insert<T>(_ node: EntityNode<T>, key: AliasKey<T>?) {
        if let key = key {
            self[key].value = node
        }
    }
    
    mutating func insert<C: Collection>(_ nodes: [EntityNode<C.Element>], key: AliasKey<C>?) {
        if let key = key {
            self[key].value = nodes
        }
    }
    
    mutating func remove<T>(for key: AliasKey<T>) {
        (self[AnyHashable(key)] as? Ref<EntityNode<T>?>)?.value = nil
    }
    
    mutating func remove<C: Collection>(for key: AliasKey<C>) {
        (self[AnyHashable(key)] as? Ref<[EntityNode<C.Element>]?>)?.value = nil
    }
}
