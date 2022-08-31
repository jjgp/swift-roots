public protocol StateContainer {
    associatedtype State

    var state: State { get }

    func send(_ action: Action)
}

public struct AnyStateContainer<State>: StateContainer {
    private let getState: () -> State
    private let dispatch: Dispatch

    public init(getState: @escaping () -> State, send: @escaping Dispatch) {
        self.getState = getState
        dispatch = send
    }

    public init<S: StateContainer>(_ stateContainer: S) where S.State == State {
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
}
