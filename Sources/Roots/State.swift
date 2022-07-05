public protocol State: Equatable {
    associatedtype Action: RawRepresentable where Action.RawValue == String
}
