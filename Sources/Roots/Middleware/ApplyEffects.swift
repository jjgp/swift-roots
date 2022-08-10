import Combine

public func apply<State, Action>(effects: Effect<State, Action>...) -> Middleware<State, Action> {
    apply(effects: effects)
}

public func apply<State, Action>(effects: [Effect<State, Action>]) -> Middleware<State, Action> {
    .init { store in
        { next in
            ApplyEffect(combine(effects: effects), to: store, chainingTo: next).respond(to:)
        }
    }
}

struct ApplyEffect<State, Action> {
    private var cancellables = Set<AnyCancellable>()
    private let next: Dispatch<Action>
    private let store: AnyStateContainer<State, Action>
    private let transitionPublisher = PassthroughSubject<Transition<State, Action>, Never>()

    init(_ effect: Effect<State, Action>, to store: AnyStateContainer<State, Action>, chainingTo next: @escaping Dispatch<Action>) {
        self.next = next
        self.store = store

        let multicast = transitionPublisher.multicast { PassthroughSubject() }
        effect.apply(multicast.eraseToAnyPublisher(), store.send(_:), &cancellables)
        multicast.connect().store(in: &cancellables)
    }

    func respond(to action: Action) {
        next(action)
        transitionPublisher.send(.init(state: store.state, action: action))
    }
}
