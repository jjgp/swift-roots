import Combine

public final class Store<S: State, A: Action>: ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    @Published private(set) var state: S
    let actionSubject = PassthroughSubject<A, Never>()

    public init(initialState: S,
                reducer: @escaping Reducer<S, A>,
                effect: Effect<S, A>? = nil)
    {
        state = initialState
        combine(state, reducer: reducer, effect: effect)
    }

    init<ParentS: State, ParentA: Action>(
        from keyPath: WritableKeyPath<ParentS, S>,
        on parent: Store<ParentS, ParentA>,
        reducer: @escaping Reducer<S, A>,
        effect: Effect<S, A>? = nil
    ) {
        // TODO: cache the children store and return it for subsequent calls. Would be ideal if
        // it was weakly referenced... and/or share the $state reference. This may need to refactor
        // away from using @Published?
        state = parent.state[keyPath: keyPath]
        combine(state, reducer: reducer, effect: effect) { [weak parent] nextState in
            parent?.state[keyPath: keyPath] = nextState
        }
    }
}

private extension Store {
    @inline(__always)
    func combine(
        _ state: S,
        reducer: @escaping Reducer<S, A>,
        effect: Effect<S, A>?,
        onUpdateState: ((S) -> Void)? = nil
    ) {
        let transitionPublisher = actionSubject
            .scan(state) { [weak self] previousState, action in
                var nextState = previousState
                nextState = reducer(&nextState, action)
                if previousState != nextState {
                    onUpdateState?(nextState)
                    self?.state = nextState
                }
                return nextState
            }
            .zip(actionSubject)
            .map(Transition.init(state:action:))
            .share()

        (effect ?? .noEffect)
            .effect(transitionPublisher.eraseToAnyPublisher()) { [weak self] action in
                self?.actionSubject.send(action)
            }
            .store(in: &cancellables)
    }
}

public extension Store {
    func store<ChildS: State, ChildA: Action>(
        from keyPath: WritableKeyPath<S, ChildS>,
        reducer: @escaping Reducer<ChildS, ChildA>,
        effect: Effect<ChildS, ChildA>? = nil
    ) -> Store<ChildS, ChildA> {
        Store<ChildS, ChildA>(from: keyPath, on: self, reducer: reducer, effect: effect)
    }
}

public extension Store {
    func send(_ action: A) {
        actionSubject.send(action)
    }
}
