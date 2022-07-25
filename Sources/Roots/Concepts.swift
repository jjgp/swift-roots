public typealias Reducer<S: State, Action> = (inout S, Action) -> S

public protocol State: Equatable {}

public struct Transition<S: State, Action> {
    public let state: S
    public let action: Action
}
