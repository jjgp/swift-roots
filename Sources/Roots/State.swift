public protocol State: Equatable {
    associatedtype Action: RawRepresentable where Action.RawValue == String

    static func reducer(state: inout Self, action: Action) -> Self
}
