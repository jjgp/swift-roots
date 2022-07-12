import Combine

public final class Store<S: State, A: Action>: ActionSubject, Publisher {
    private(set) var cancellables: Set<AnyCancellable> = []
    private var stateBinding: StateBinding<S>
    let actionSubject = PassthroughSubject<A, Never>()

    public convenience init(initialState: S,
                            reducer: @escaping Reducer<S, A>,
                            effect: Effect<S, A>? = nil)
    {
        let stateBinding = StateBinding(initialState: initialState)
        self.init(stateBinding: stateBinding, reducer: reducer, effect: effect)
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
            .share()

        (effect ?? .noEffect)
            .effect(transitionPublisher.eraseToAnyPublisher()) { [weak self] action in
                self?.actionSubject.send(action)
            }
            .store(in: &cancellables)
    }
}

public extension Store {
    func scope<ChildState: State, ChildAction: Action>(
        to keyPath: WritableKeyPath<S, ChildState>,
        reducer: @escaping Reducer<ChildState, ChildAction>,
        effect: Effect<ChildState, ChildAction>? = nil
    ) -> Store<ChildState, ChildAction> {
        let stateBinding = stateBinding.scope(keyPath)
        return Store<ChildState, ChildAction>(stateBinding: stateBinding, reducer: reducer, effect: effect)
    }
}

public extension Store {
    func send(_ action: A) {
        actionSubject.send(action)
    }
}

public extension Store {
    typealias Output = S
    typealias Failure = Never

    func receive<Subscriber: Combine.Subscriber>(subscriber: Subscriber) where Never == Subscriber.Failure, S == Subscriber
        .Input
    {
        stateBinding.removeDuplicates().receive(subscriber: subscriber)
    }
}
