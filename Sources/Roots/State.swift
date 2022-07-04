public protocol State: Equatable {
    associatedtype Action: RawRepresentable where Action.RawValue == String

    static func map(with store: Store<Self>)
}
