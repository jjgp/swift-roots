import Combine

public final class Store<S: State, Action>: Publisher {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private let stateBinding: StateBinding<S>

    public convenience init(initialState: S,
                            reducer: @escaping Reducer<S, Action>,
                            effect: Effect<S, Action>? = nil)
    {
        self.init(stateBinding: StateBinding(initialState: initialState), reducer: reducer, effect: effect)
    }

    init(stateBinding: StateBinding<S>,
         reducer: @escaping Reducer<S, Action>,
         effect: Effect<S, Action>? = nil)
    {
        self.stateBinding = stateBinding
        let transitionPublisher = actionSubject
            .map { action -> Transition<S, Action> in
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
    func receive<Subscriber: Combine.Subscriber>(subscriber: Subscriber) where Never == Subscriber.Failure, S == Subscriber
        .Input
    {
        stateBinding.removeDuplicates().receive(subscriber: subscriber)
    }

    typealias Failure = Never
    typealias Output = S
}

public extension Store {
    func scope<StateInScope: State, ActionInScope>(
        to keyPath: WritableKeyPath<S, StateInScope>,
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
}
