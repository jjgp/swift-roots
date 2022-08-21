import Combine

public final class ApplyEpics<State, Action>: Middleware<State, Action> {
    private let actionPublisher = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let statePublisher = PassthroughSubject<State, Never>()

    private init(epic: Epic<State, Action>) {
        super.init()

        epic
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

public extension ApplyEpics {
    convenience init(_ epics: Epic<State, Action>...) {
        self.init(epics)
    }

    convenience init(_ epics: [Epic<State, Action>]) {
        self.init(epic: .combine(epics: epics))
    }

    convenience init<Dependencies>(
        dependencies: Dependencies,
        and dependentEpics: DependentEpic<State, Action, Dependencies>...
    ) {
        self.init(dependencies: dependencies, and: dependentEpics)
    }

    convenience init<Dependencies>(
        dependencies: Dependencies,
        and dependentEpics: [DependentEpic<State, Action, Dependencies>]
    ) {
        self.init(epic: .combine(dependencies: dependencies, and: dependentEpics))
    }
}
