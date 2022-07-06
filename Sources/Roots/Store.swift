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

        let nextState = subject
            .scan(initialState) { state, action in
                // Each subscription will rerun this send block. And since both have views to
                // the value type semantics of an initial state. Their subscription will result in updating
                // two views of the same initial state. One will update the store and the other will update the
                // effect. Need to combine into one stream and update the state and effect consistently to
                // rid this of the errors
                var state = state
                let nextState = reducer(&state, action)
                print("in reducer")
                print(nextState, action)
                return nextState
            }

        nextState
            .removeDuplicates()
            .assign(to: \.state, on: self)
            .store(in: &cancellables)

        nextState
            .zip(subject)
            .sink(receiveValue: { print($0) })
            .store(in: &cancellables)

        effect?
            .effect(
                nextState.zip(subject).eraseToAnyPublisher(),
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
