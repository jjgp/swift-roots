public protocol Action {}

public typealias Reducer<State, Action> = (inout State, Action) -> State

public struct Transition<State, Action> {
    public let state: State
    public let action: Action

    public init(state: State, action: Action) {
        self.action = action
        self.state = state
    }
}
