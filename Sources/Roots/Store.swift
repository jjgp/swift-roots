import Combine

public final class Store<State, Action>: Publisher, StateContainer {
    private var innerSend: Dispatch<Action>!
    private let stateBinding: StateBinding<State>

    public init(stateBinding: StateBinding<State>,
                reducer: @escaping Reducer<State, Action>,
                middleware: Middleware<State, Action>? = nil)
    {
        self.stateBinding = stateBinding

        let innerSend: Dispatch<Action> = { action in
            var state = stateBinding.wrappedState
            stateBinding.wrappedState = reducer(&state, action)
        }

        if let middleware = middleware {
            self.innerSend = middleware.createDispatch(toAnyStateContainer())(innerSend)
        } else {
            self.innerSend = innerSend
        }
    }
}

// MARK: - Convenience initializers

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

// MARK: - Publisher conformance

public extension Store {
    func receive<S: Subscriber>(subscriber: S) where S.Failure == Never, S.Input == State {
        stateBinding.receive(subscriber: subscriber)
    }

    typealias Failure = Never
    typealias Output = State
}

// MARK: - StateContainer conformance

public extension Store {
    var state: State {
        stateBinding.wrappedState
    }

    func send(_ action: Action) {
        innerSend(action)
    }

    func toAnyStateContainer() -> AnyStateContainer<State, Action> {
        var previousState = state
        return AnyStateContainer(
            getState: { [weak self] in
                guard let self = self else {
                    return previousState
                }

                return self.state
            },
            send: { [weak self] action in
                guard let self = self else {
                    return
                }

                self.send(action)
                previousState = self.state
            }
        )
    }
}

// MARK: - Store in scope

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
        isDuplicate predicate: @escaping (StateInScope, StateInScope) -> Bool,
        reducer: @escaping Reducer<StateInScope, ActionInScope>,
        middleware: Middleware<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> {
        .init(stateBinding: stateBinding.scope(keyPath, isDuplicate: predicate), reducer: reducer, middleware: middleware)
    }

    func scope<StateInScope: Equatable, ActionInScope>(
        to keyPath: WritableKeyPath<State, StateInScope>,
        reducer: @escaping Reducer<StateInScope, ActionInScope>,
        middleware: Middleware<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> {
        .init(stateBinding: stateBinding.scope(keyPath), reducer: reducer, middleware: middleware)
    }
}
