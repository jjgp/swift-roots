import Combine

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

public extension Middleware {
    static func apply(effects: Effect<State, Action>...) -> Self {
        .apply(effects: effects)
    }

    static func apply(effects: [Effect<State, Action>]) -> Self {
        .init { store in
            { next in
                ApplyEffect(.combine(effects: effects), to: store, chainingTo: next).respond(to:)
            }
        }
    }

    // TODO: context effects
}
