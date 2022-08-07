public struct Transition<State, Action> {
    public let state: State
    public let action: Action

    public init(state: State, action: Action) {
        self.action = action
        self.state = state
    }
}
