public protocol State: Equatable {
    associatedtype Action: RawRepresentable where Action.RawValue == String

    static func reducer(state: inout Self, action: Action) -> Self
}

public enum Inaction {}

extension Inaction: RawRepresentable {
    // TODO: fill in the fatalError()
    public var rawValue: String {
        fatalError()
    }

    public init?(rawValue _: String) {
        fatalError()
    }

    public typealias RawValue = String
}
