import Combine

public struct StateBinding<State>: Publisher {
    private let getState: () -> State
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
        getState: @escaping () -> State,
        setState: @escaping (State) -> Void,
        statePublisher: AnyPublisher<State, Never>
    ) {
        self.getState = getState
        self.setState = setState
        self.statePublisher = statePublisher
    }

    public typealias Failure = Never
    public typealias Output = State
}

public extension StateBinding {
    init(initialState: State) {
        let subject = CurrentValueSubject<State, Never>(initialState)
        self.init(
            getState: {
                subject.value
            },
            setState: { newState in
                subject.value = newState
            },
            statePublisher: subject.eraseToAnyPublisher()
        )
    }

    init(initialState: State) where State: Equatable {
        // TODO:
        let subject = CurrentValueSubject<State, Never>(initialState)
        self.init(
            getState: {
                subject.value
            },
            setState: { newState in
                subject.value = newState
            },
            statePublisher: subject.removeDuplicates().eraseToAnyPublisher()
        )
    }
}

public extension StateBinding {
    func receive<S: Subscriber>(
        subscriber: S
    ) where S.Failure == Failure, S.Input == State {
        statePublisher.receive(subscriber: subscriber)
    }
}

public extension StateBinding {
    func scope<StateInScope>(_ keyPath: WritableKeyPath<State, StateInScope>) -> StateBinding<StateInScope> {
        StateBinding<StateInScope>(
            getState: {
                wrappedState[keyPath: keyPath]
            },
            setState: { newState in
                wrappedState[keyPath: keyPath] = newState
            },
            statePublisher: statePublisher.map(keyPath).eraseToAnyPublisher()
        )
    }

    func scope<StateInScope>(_ keyPath: WritableKeyPath<State, StateInScope>) -> StateBinding<StateInScope> where StateInScope: Equatable {
        StateBinding<StateInScope>(
            getState: {
                wrappedState[keyPath: keyPath]
            },
            setState: { newState in
                wrappedState[keyPath: keyPath] = newState
            },
            statePublisher: statePublisher.map(keyPath).removeDuplicates().eraseToAnyPublisher()
        )
    }
}
