import Combine

public final class ApplyEffect<State, Action>: Middleware<State, Action> {
    private let actionPublisher = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let statePublisher = PassthroughSubject<State, Never>()

    private init(effect: Effect<State, Action>) {
        super.init()

        effect
            .createPublisher(statePublisher.eraseToAnyPublisher(), actionPublisher.eraseToAnyPublisher())
            .sink { [weak self] action in
                self?.store.send(action)
            }
            .store(in: &cancellables)
    }

    override public func respond(to action: Action, forwardingTo next: (Action) -> Void) {
        next(action)
        statePublisher.send(store.state)
        actionPublisher.send(action)
    }
}

public extension ApplyEffect {
    convenience init(effects: Effect<State, Action>...) {
        self.init(effects: effects)
    }

    convenience init(effects: [Effect<State, Action>]) {
        self.init(effect: .combine(effects: effects))
    }

    convenience init<Context>(
        context: Context,
        and contextEffects: ContextEffect<State, Action, Context>...
    ) {
        self.init(context: context, and: contextEffects)
    }

    convenience init<Context>(
        context: Context,
        and contextEffects: [ContextEffect<State, Action, Context>]
    ) {
        self.init(effect: .combine(context: context, and: contextEffects))
    }
}
