public protocol Action: Equatable {}

public typealias Reducer<S: State, A: Action> = (inout S, A) -> S

public protocol State: Equatable {}

public struct Transition<S: State, A: Action> {
    public let state: S
    public let action: A
}
