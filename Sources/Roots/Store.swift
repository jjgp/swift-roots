import Combine

public final class Store<State, Action>: StateContainer, Publisher {
    private var innerSend: Dispatch<Action>!
    private let stateBinding: StateBinding<State>

    public init(stateBinding: StateBinding<State>,
                reducer: @escaping Reducer<State, Action>,
                middleware: Middleware<State, Action>? = nil)
    {
        self.stateBinding = stateBinding

        let innerSend = { action in
            var state = stateBinding.wrappedState
            stateBinding.wrappedState = reducer(&state, action)
        }

        if let middleware {
            self.innerSend = middleware.createDispatch(toAnyStateContainer())(innerSend)
        } else {
            self.innerSend = innerSend
        }
    }
}

public extension Store {
    convenience init(initialState: State,
                     reducer: @escaping Reducer<State, Action>,
                     middleware: Middleware<State, Action>? = nil)
    {
        self.init(stateBinding: .init(initialState: initialState), reducer: reducer, middleware: middleware)
    }

    convenience init(initialState: State,
                     reducer: @escaping Reducer<State, Action>,
                     middleware: Middleware<State, Action>? = nil) where State: Equatable
    {
        self.init(stateBinding: .init(initialState: initialState), reducer: reducer, middleware: middleware)
    }
}

public extension Store {
    func receive<S: Subscriber>(subscriber: S) where S.Failure == Never, S.Input == State {
        stateBinding.receive(subscriber: subscriber)
    }

    typealias Failure = Never
    typealias Output = State
}

public extension Store {
    func scope<StateInScope, ActionInScope>(
        to keyPath: WritableKeyPath<State, StateInScope>,
        reducer: @escaping Reducer<StateInScope, ActionInScope>,
        middleware: Middleware<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> {
        .init(stateBinding: stateBinding.scope(keyPath), reducer: reducer, middleware: middleware)
    }

    func scope<StateInScope, ActionInScope>(
        to keyPath: WritableKeyPath<State, StateInScope>,
        reducer: @escaping Reducer<StateInScope, ActionInScope>,
        middleware: Middleware<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> where StateInScope: Equatable {
        .init(stateBinding: stateBinding.scope(keyPath), reducer: reducer, middleware: middleware)
    }
}

public extension Store {
    var state: State {
        stateBinding.wrappedState
    }

    func send(_ action: Action) {
        innerSend(action)
    }

    func toAnyStateContainer() -> AnyStateContainer<State, Action> {
        var previousState = state
        let getState = { [weak self] in
            guard let self else {
                return previousState
            }

            defer {
                previousState = self.state
            }

            return self.state
        }

        return AnyStateContainer(getState: getState, send: { [weak self] action in
            self?.send(action)
        })
    }
}

public extension Store {
    private func actionCreator<T>(for keyPath: KeyPath<State, T>) -> T {
        stateBinding.wrappedState[keyPath: keyPath]
    }

    // TODO: rename the following...

    // swiftlint:disable function_parameter_count identifier_name
    func send(from keyPath: KeyPath<State, Action>) {
        send(actionCreator(for: keyPath))
    }

    func send<A>(from keyPath: KeyPath<State, (A) -> Action>, _ a: A) {
        send(actionCreator(for: keyPath)(a))
    }

    func send<A, B>(from keyPath: KeyPath<State, (A, B) -> Action>, _ a: A, _ b: B) {
        send(actionCreator(for: keyPath)(a, b))
    }

    func send<A, B, C>(from keyPath: KeyPath<State, (A, B, C) -> Action>, _ a: A, _ b: B, _ c: C) {
        send(actionCreator(for: keyPath)(a, b, c))
    }

    func send<A, B, C, D>(from keyPath: KeyPath<State, (A, B, C, D) -> Action>, _ a: A, _ b: B, _ c: C, _ d: D) {
        send(actionCreator(for: keyPath)(a, b, c, d))
    }

    func send<A, B, C, D, E>(
        from keyPath: KeyPath<State, (A, B, C, D, E) -> Action>,
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E
    ) {
        send(actionCreator(for: keyPath)(a, b, c, d, e))
    }
    // swiftlint:enable function_parameter_count identifier_name
}
