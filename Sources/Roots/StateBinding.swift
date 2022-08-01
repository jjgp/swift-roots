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
}

public extension StateBinding {
    func receive<Subscriber: Combine.Subscriber>(
        subscriber: Subscriber
    ) where Failure == Subscriber.Failure, Output == Subscriber.Input {
        statePublisher.receive(subscriber: subscriber)
    }

    typealias Failure = Never
    typealias Output = State
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
            statePublisher: map(keyPath).eraseToAnyPublisher()
        )
    }
}
