import Combine

struct StateBinding<S: State> {
    private let getState: () -> S
    private let setState: (S) -> Void
    private let setSubscriber: (AnySubscriber<S, Never>) -> Void
    var wrappedState: S {
        get { getState() }
        nonmutating set { setState(newValue) }
    }

    private init(
        getState: @escaping () -> S,
        setState: @escaping (S) -> Void,
        setSubscriber: @escaping (AnySubscriber<S, Never>) -> Void
    ) {
        self.getState = getState
        self.setState = setState
        self.setSubscriber = setSubscriber
    }
}

extension StateBinding {
    init(initialState: S) {
        let subject = CurrentValueSubject<S, Never>(initialState)
        self.init(
            getState: { subject.value },
            setState: { subject.value = $0 },
            setSubscriber: { subject.receive(subscriber: $0) }
        )
    }
}

extension StateBinding: Publisher {
    func receive<Subscriber: Combine.Subscriber>(
        subscriber: Subscriber
    ) where Failure == Subscriber.Failure, Output == Subscriber.Input {
        setSubscriber(AnySubscriber(subscriber))
    }

    typealias Failure = Never
    typealias Output = S
}

extension StateBinding {
    func scope<ChildState: State>(_ keyPath: WritableKeyPath<S, ChildState>) -> StateBinding<ChildState> {
        let mappedPublisher = map(keyPath)
        return StateBinding<ChildState>(
            getState: { wrappedState[keyPath: keyPath] },
            setState: { wrappedState[keyPath: keyPath] = $0 },
            setSubscriber: { mappedPublisher.receive(subscriber: $0) }
        )
    }
}
