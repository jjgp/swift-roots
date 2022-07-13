import Combine

public func applyEffects<S: State, A: Action>(effects: Effect<S, A>...) -> Effect<S, A> {
    applyEffects(effects: effects)
}

public func applyEffects<S: State, A: Action>(effects: [Effect<S, A>]) -> Effect<S, A> {
    Effect(effect: { transitionPublisher, send in
        let cancellables = effects.map { $0.effect(transitionPublisher, send) }
        return AnyCancellable {
            cancellables.forEach {
                $0.cancel()
            }
        }
    })
}

public struct Effect<S: State, A: Action> {
    let effect: Effect

    public init(effect: @escaping Effect) {
        self.effect = effect
    }

    public init<P: Publisher>(
        publisher: @escaping (TransitionPublisher) -> P
    ) where P.Output == A, P.Failure == Never {
        effect = {
            publisher($0)
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public init(sender: @escaping (S, A, @escaping Send) -> Void) {
        effect = { actionPairPublisher, send in
            actionPairPublisher.sink { pair in
                sender(pair.state, pair.action, send)
            }
        }
    }

    public init(sender: @escaping (S, A, @escaping Send) async -> Void) {
        self.init { state, action, send in
            Task {
                await sender(state, action, send)
            }
        }
    }

    public init(sink: @escaping (TransitionPublisher) -> AnyCancellable) {
        effect = { actionPairPublisher, _ in
            sink(actionPairPublisher)
        }
    }

    public typealias Effect = (TransitionPublisher, @escaping Send) -> AnyCancellable
    public typealias TransitionPublisher = AnyPublisher<Transition<S, A>, Never>
    public typealias Send = (A) -> Void
}

public extension Effect {
    static func effect(effect: @escaping Effect) -> Self {
        self.init(effect: effect)
    }

    static func publisher<P: Publisher>(
        publisher: @escaping (TransitionPublisher) -> P
    ) -> Self where P.Output == A, P.Failure == Never {
        self.init(publisher: publisher)
    }

    static func sender(sender: @escaping (S, A, @escaping Send) -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sender(sender: @escaping (S, A, @escaping Send) async -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sink(sink: @escaping (TransitionPublisher) -> AnyCancellable) -> Self {
        self.init(sink: sink)
    }
}
