public protocol Action: Equatable {}

public typealias Reducer<S: State, A: Action> = (inout S, A) -> S

public protocol State: Equatable {}

public struct Transition<S: State, A: Action> {
    let state: S
    let action: A
}
