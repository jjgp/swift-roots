public protocol Action {}

public typealias Dispatch<Action> = (Action) -> Void

public typealias Reducer<State, Action> = (inout State, Action) -> State

public protocol StateContainer {
    associatedtype State
    associatedtype Action

    var state: State { get }

    func send(_ action: Action)
    func toAnyStateContainer() -> AnyStateContainer<State, Action>
}

public struct Transition<State, Action> {
    public let state: State
    public let action: Action

    public init(state: State, action: Action) {
        self.action = action
        self.state = state
    }
}
