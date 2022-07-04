public protocol State: Equatable {
    associatedtype Action: RawRepresentable where Action.RawValue == String

    /* TODO:
     - support mapping of state tree
     - need to be able to supply reducer, middleware, effects
     */
    static func map(with store: Store<Self>)

    static func reducer(state: inout Self, action: Action) -> Self
}
