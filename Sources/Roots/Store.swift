import Combine

public final class Store<S: State>: ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    let subject = PassthroughSubject<Action, Never>()
    @Published private(set) var state: S

    public init(initialState: S,
                reducer: @escaping Reducer<S>,
                effect: Effect<S>? = nil)
    {
        state = initialState
        let stateActionPair = subject
            .scan(initialState) { [weak self] previousState, action in
                var nextState = previousState
                nextState = reducer(&nextState, action)
                if previousState != nextState {
                    self?.state = nextState
                }
                return nextState
            }
            .zip(subject)
            .eraseToAnyPublisher()

        effect?
            .effect(
                stateActionPair,
                subject.send(_:)
            )
            .store(in: &cancellables)
    }

    init<Parent: State>(
        from keyPath: WritableKeyPath<Parent, S>,
        on parent: Store<Parent>,
        reducer: @escaping Reducer<S>,
        effect: Effect<S>? = nil
    ) {
        state = parent.state[keyPath: keyPath]
        combine(parent.state, on: parent, effect: effect) { parentState, action in
            var parentState = parentState
            var childState = parentState[keyPath: keyPath]
            parentState[keyPath: keyPath] = reducer(&childState, action)
            return parentState
        }
        parent
            .$state
            .map(keyPath)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

private extension Store {
    @inline(__always)
    func combine<T: State, Root: Store<T>>(
        _: T,
        on _: Root,
        effect _: Effect<S>?,
        _: @escaping (T, Action) -> T
    ) {
//        let nextState = subject
//            .scan(initialState, nextPartialState)
//
//        nextState
//            .removeDuplicates()
//            .assign(to: \.state, on: store)
//            .store(in: &cancellables)
//
//        effect?
//            .effect(
//                nextState.zip(subject),
//                subject.send
//            )
//            .store(in: &cancellables)
    }
}

public extension Store {
    func store<T: State>(
        from keyPath: WritableKeyPath<S, T>,
        reducer: @escaping Reducer<T>
    ) -> Store<T> {
        Store<T>(from: keyPath, on: self, reducer: reducer)
    }
}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
