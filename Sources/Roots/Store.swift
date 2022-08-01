import Combine

public final class Store<State: Equatable, Action>: Publisher {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private let stateBinding: StateBinding<State>

    public convenience init(initialState: State,
                            reducer: @escaping Reducer<State, Action>,
                            effect: Effect<State, Action>? = nil)
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
                if stateBinding.wrappedState != nextState {
                    stateBinding.wrappedState = nextState
                }
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
    func receive<Subscriber: Combine.Subscriber>(subscriber: Subscriber) where Subscriber.Failure == Never, Subscriber.Input == State
    {
        stateBinding.removeDuplicates().receive(subscriber: subscriber)
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
}

public extension Store {
    func send(_ action: Action) {
        actionSubject.send(action)
    }

    func send(_ keyPath: KeyPath<State, Action>) {
        actionSubject.send(stateBinding.wrappedState[keyPath: keyPath])
    }

    func send<T>(_ keyPath: KeyPath<State, (T) -> Action>, _ value: T) {
        actionSubject.send(stateBinding.wrappedState[keyPath: keyPath](value))
    }
}
