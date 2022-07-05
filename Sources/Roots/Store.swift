import Combine

public final class Store<S: State>: StatePublisher, ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    let subject = PassthroughSubject<Action, Never>()
    @Published private(set) var state: S
    var statePublished: Published<S> { _state }
    var statePublisher: Published<S>.Publisher { $state }

    public init(initialState: S) {
        state = initialState
        combine(state, to: self) { state, action in
            var state = state
            return S.reducer(state: &state, action: action)
        }
    }

    init<Parent: State>(
        from keyPath: WritableKeyPath<Parent, S>,
        on parent: Store<Parent>
    ) {
        state = parent.state[keyPath: keyPath]
        combine(parent.state, to: parent) { parentState, action in
            var parentState = parentState
            var childState = parentState[keyPath: keyPath]
            parentState[keyPath: keyPath] = S.reducer(state: &childState, action: action)
            return parentState
        }
        parent
            .statePublisher
            .map(keyPath)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

private extension Store {
    func combine<T: State, Root: Store<T>>(
        _ initialState: T,
        to store: Root,
        _ nextPartialState: @escaping (T, Action) -> T
    ) {
        subject
            .scan(initialState, nextPartialState)
            .removeDuplicates()
            .assign(to: \.state, on: store)
            .store(in: &cancellables)
    }
}

public extension Store {
    func store<T: State>(from keyPath: WritableKeyPath<S, T>) -> Store<T> {
        Store<T>(from: keyPath, on: self)
    }
}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
