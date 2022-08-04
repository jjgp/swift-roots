import Combine

public final class Store<State, Action>: Publisher {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private let stateBinding: StateBinding<State>

    public convenience init(initialState: State,
                            reducer: @escaping Reducer<State, Action>,
                            effect: Effect<State, Action>? = nil)
    {
        self.init(stateBinding: StateBinding(initialState: initialState), reducer: reducer, effect: effect)
    }

    public convenience init(initialState: State,
                            reducer: @escaping Reducer<State, Action>,
                            effect: Effect<State, Action>? = nil) where State: Equatable
    {
        self.init(stateBinding: StateBinding(initialState: initialState), reducer: reducer, effect: effect)
    }

    init(stateBinding: StateBinding<State>,
         reducer: @escaping Reducer<State, Action>,
         effect: Effect<State, Action>? = nil)
    {
        self.stateBinding = stateBinding
        let transitionPublisher = actionSubject
            .map { action -> Transition<State, Action> in
                var nextState = stateBinding.wrappedState
                nextState = reducer(&nextState, action)
                stateBinding.wrappedState = nextState
                return Transition(state: nextState, action: action)
            }

        if let effect = effect {
            let multicastPublisher = transitionPublisher.multicast { PassthroughSubject() }
            effect.apply(multicastPublisher.eraseToAnyPublisher(), actionSubject.send(_:), &cancellables)
            multicastPublisher.connect().store(in: &cancellables)
        } else {
            transitionPublisher.ignoreOutput().sink { _ in }.store(in: &cancellables)
        }
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
        effect: Effect<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> {
        Store<StateInScope, ActionInScope>(
            stateBinding: stateBinding.scope(keyPath),
            reducer: reducer,
            effect: effect
        )
    }

    func scope<StateInScope, ActionInScope>(
        to keyPath: WritableKeyPath<State, StateInScope>,
        reducer: @escaping Reducer<StateInScope, ActionInScope>,
        effect: Effect<StateInScope, ActionInScope>? = nil
    ) -> Store<StateInScope, ActionInScope> where StateInScope: Equatable {
        Store<StateInScope, ActionInScope>(
            stateBinding: stateBinding.scope(keyPath),
            reducer: reducer,
            effect: effect
        )
    }
}

public extension Store {
    func send(_ action: Action) {
        actionSubject.send(action)
    }
}

public extension Store {
    private func actionCreator<T>(for keyPath: KeyPath<State, T>) -> T {
        stateBinding.wrappedState[keyPath: keyPath]
    }

    // swiftlint:disable function_parameter_count identifier_name
    func send(_ keyPath: KeyPath<State, Action>) {
        send(actionCreator(for: keyPath))
    }

    func send<A>(_ keyPath: KeyPath<State, (A) -> Action>, _ a: A) {
        send(actionCreator(for: keyPath)(a))
    }

    func send<A, B>(_ keyPath: KeyPath<State, (A, B) -> Action>, _ a: A, _ b: B) {
        send(actionCreator(for: keyPath)(a, b))
    }

    func send<A, B, C>(_ keyPath: KeyPath<State, (A, B, C) -> Action>, _ a: A, _ b: B, _ c: C) {
        send(actionCreator(for: keyPath)(a, b, c))
    }

    func send<A, B, C, D>(_ keyPath: KeyPath<State, (A, B, C, D) -> Action>, _ a: A, _ b: B, _ c: C, _ d: D) {
        send(actionCreator(for: keyPath)(a, b, c, d))
    }

    func send<A, B, C, D, E>(
        _ keyPath: KeyPath<State, (A, B, C, D, E) -> Action>,
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E
    ) {
        send(actionCreator(for: keyPath)(a, b, c, d, e))
    }
    // swiftlint:enable function_parameter_count identifier_name
}
