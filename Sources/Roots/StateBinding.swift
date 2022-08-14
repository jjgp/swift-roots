import Combine

public struct StateBinding<State>: Publisher {
    private let getState: GetState<State>
    private let setState: (State) -> Void
    private let statePublisher: AnyPublisher<State, Never>
    public var wrappedState: State {
        get {
            getState()
        }
        nonmutating set {
            setState(newValue)
        }
    }

    private init(
        getState: @escaping GetState<State>,
        setState: @escaping (State) -> Void,
        statePublisher: AnyPublisher<State, Never>
    ) {
        self.getState = getState
        self.setState = setState
        self.statePublisher = statePublisher
    }
}

public extension StateBinding {
    init(initialState: State, isDuplicate predicate: @escaping (State, State) -> Bool = { _, _ in false }) {
        let subject = CurrentValueSubject<State, Never>(initialState)
        self.init(
            getState: {
                subject.value
            },
            setState: { newState in
                subject.value = newState
            },
            statePublisher: subject.removeDuplicates(by: predicate).eraseToAnyPublisher()
        )
    }

    init(initialState: State) where State: Equatable {
        self.init(initialState: initialState, isDuplicate: ==)
    }
}

public extension StateBinding {
    func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure, S.Input == State {
        statePublisher.receive(subscriber: subscriber)
    }

    typealias Failure = Never
    typealias Output = State
}

public extension StateBinding {
    func scope<StateInScope>(
        _ keyPath: WritableKeyPath<State, StateInScope>,
        isDuplicate predicate: @escaping (StateInScope, StateInScope) -> Bool = { _, _ in false }
    ) -> StateBinding<StateInScope> {
        StateBinding<StateInScope>(
            getState: {
                wrappedState[keyPath: keyPath]
            },
            setState: { newState in
                wrappedState[keyPath: keyPath] = newState
            },
            statePublisher: statePublisher.map(keyPath).removeDuplicates(by: predicate).eraseToAnyPublisher()
        )
    }

    func scope<StateInScope: Equatable>(_ keyPath: WritableKeyPath<State, StateInScope>) -> StateBinding<StateInScope> {
        scope(keyPath, isDuplicate: ==)
    }
}
