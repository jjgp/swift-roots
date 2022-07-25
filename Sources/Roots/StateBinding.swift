import Combine

public struct StateBinding<S: State>: Publisher {
    private let getState: () -> S
    private let setState: (S) -> Void
    private let statePublisher: AnyPublisher<S, Never>
    public var wrappedState: S {
        get {
            getState()
        }
        nonmutating set {
            setState(newValue)
        }
    }

    private init(
        getState: @escaping () -> S,
        setState: @escaping (S) -> Void,
        statePublisher: AnyPublisher<S, Never>
    ) {
        self.getState = getState
        self.setState = setState
        self.statePublisher = statePublisher
    }
}

public extension StateBinding {
    init(initialState: S) {
        let subject = CurrentValueSubject<S, Never>(initialState)
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
    typealias Output = S
}

public extension StateBinding {
    func scope<StateInScope: State>(_ keyPath: WritableKeyPath<S, StateInScope>) -> StateBinding<StateInScope> {
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
