public struct AnyStateContainer<State, Action>: StateContainer {
    private let getState: () -> State
    private let dispatch: Dispatch<Action>

    public init(getState: @escaping () -> State, send: @escaping Dispatch<Action>) {
        self.getState = getState
        dispatch = send
    }

    public init<S: StateContainer>(_ stateContainer: S) where S.State == State, S.Action == Action {
        self.init(getState: { stateContainer.state }, send: stateContainer.send(_:))
    }
}

public extension AnyStateContainer {
    var state: State {
        getState()
    }

    func send(_ action: Action) {
        dispatch(action)
    }

    func toAnyStateContainer() -> AnyStateContainer<State, Action> {
        self
    }
}
