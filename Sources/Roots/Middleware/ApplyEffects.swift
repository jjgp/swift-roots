import Combine

struct ApplyEffect<State, Action> {
    private let actionPublisher = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let next: Dispatch<Action>
    private let statePublisher = PassthroughSubject<State, Never>()
    private let store: AnyStateContainer<State, Action>

    init(_ effect: Effect<State, Action>, to store: AnyStateContainer<State, Action>, chainingTo next: @escaping Dispatch<Action>) {
        self.next = next
        self.store = store

        effect
            .createPublisher(statePublisher.eraseToAnyPublisher(), actionPublisher.eraseToAnyPublisher())
            .sink(receiveValue: store.send(_:))
            .store(in: &cancellables)
    }

    func respond(to action: Action) {
        next(action)
        statePublisher.send(store.state)
        actionPublisher.send(action)
    }
}

public extension Middleware {
    static func apply(effects: Effect<State, Action>...) -> Self {
        .apply(effects: effects)
    }

    static func apply(effects: [Effect<State, Action>]) -> Self {
        .init { store, next in
            ApplyEffect(.combine(effects: effects), to: store, chainingTo: next).respond(to:)
        }
    }

    static func apply<Context>(
        context: Context,
        and contextEffects: ContextEffect<State, Action, Context>...
    ) -> Self {
        .apply(context: context, and: contextEffects)
    }

    static func apply<Context>(
        context: Context,
        and contextEffects: [ContextEffect<State, Action, Context>]
    ) -> Self {
        .init { store, next in
            ApplyEffect(.combine(context: context, and: contextEffects), to: store, chainingTo: next).respond(to:)
        }
    }
}
