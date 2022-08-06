public protocol Action {}

public protocol Middleware {
    associatedtype State
    associatedtype Action

    func respond(to action: Action, sentTo store: Store<State, Action>, chainingTo next: Dispatch<Action>)
}

public typealias Reducer<State, Action> = (inout State, Action) -> State

public typealias Dispatch<Action> = (Action) -> Void

public struct Transition<State, Action> {
    public let state: State
    public let action: Action

    public init(state: State, action: Action) {
        self.action = action
        self.state = state
    }
}
