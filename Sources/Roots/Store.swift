import Combine

public final class Store<S: State, A: Action>: Publisher {
    private let actionSubject = PassthroughSubject<A, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private let stateBinding: StateBinding<S>

    public convenience init(initialState: S,
                            reducer: @escaping Reducer<S, A>,
                            effect: Effect<S, A>? = nil)
    {
        self.init(stateBinding: StateBinding(initialState: initialState), reducer: reducer, effect: effect)
    }

    init(stateBinding: StateBinding<S>,
         reducer: @escaping Reducer<S, A>,
         effect: Effect<S, A>? = nil)
    {
        self.stateBinding = stateBinding
        let transitionPublisher = actionSubject
            .map { action -> Transition<S, A> in
                var nextState = stateBinding.wrappedState
                nextState = reducer(&nextState, action)
                if stateBinding.wrappedState != nextState {
                    stateBinding.wrappedState = nextState
                }
                return Transition(state: nextState, action: action)
            }
            .multicast { PassthroughSubject() }

        if let effect = effect {
            effect.apply(transitionPublisher.eraseToAnyPublisher(), actionSubject.send(_:), &cancellables)
        } else {
            transitionPublisher.ignoreOutput().sink { _ in }.store(in: &cancellables)
        }

        transitionPublisher.connect().store(in: &cancellables)
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
    func scope<StateInScope: State, ActionInScope: Action>(
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
    func send(_ action: A) {
        actionSubject.send(action)
    }
}
