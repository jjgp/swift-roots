public struct AnyStateContainer<State, Action>: StateContainer {
    ////    private let getState
//
//    public init<S: StateContainer>(_ store: S) where S.State == State, S.Action == Action {
//
//    }
//
//    public init<State, Action>(getState: () -> State, send: Dispatch<Action>) {
//
//    }
}

public extension AnyStateContainer {
    func getState() -> State {
        fatalError()
    }

    func send(_: Action) {
        fatalError()
    }

    func toAnyStateContainer() -> AnyStateContainer<State, Action> {
        fatalError()
    }
}
