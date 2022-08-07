import Combine

public func apply<State, Action>(effects: Effect<State, Action>...) -> Middleware<State, Action> {
    apply(effects: effects)
}

public func apply<State, Action>(effects: [Effect<State, Action>]) -> Middleware<State, Action> {
    var cancellables = Set<AnyCancellable>()

    return .init { store in
        let transitionPublisher = PassthroughSubject<Transition<State, Action>, Never>()
        let multicast = transitionPublisher.multicast { PassthroughSubject() }
        combine(effects: effects).apply(multicast.eraseToAnyPublisher(), store.send(_:), &cancellables)
        multicast.connect().store(in: &cancellables)

        return { next in
            { action in
                next(action)
                transitionPublisher.send(.init(state: store.state, action: action))
            }
        }
    }
}
