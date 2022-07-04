import Combine

public typealias Reducer<S: State> = (inout S, S.Action) -> S

public final class Store<S: State>: StatePublisher, ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    private(set) var subject: PassthroughSubject<Action, Never>
    @Published private(set) var state: S
    var statePublished: Published<S> { _state }
    var statePublisher: Published<S>.Publisher { $state }

    public init(initialState: S, reducer: @escaping Reducer<S>) {
        state = initialState
        subject = PassthroughSubject<Action, Never>()
        subject
            // TODO: middleware and/or effects
            .scan(initialState) { state, action in
                var state = state
                return reducer(&state, action)
            }
            .removeDuplicates()
            .assign(to: \.state, on: self)
            .store(in: &cancellables)

        // TODO: WIP
        S.map(with: self)
    }
}

public extension Store {
    @discardableResult
    func map<T: State>(child _: WritableKeyPath<S, T>) -> Self {
        /* TODO:
         - create child store tree
         - map child state back to state
         */
        self
    }

    func store<T: State>(for _: WritableKeyPath<S, T>) -> Store<T> {
        /* TODO:
         - if not registered throw
         - return child store
         */
        fatalError("Not yet implemented")
    }
}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
