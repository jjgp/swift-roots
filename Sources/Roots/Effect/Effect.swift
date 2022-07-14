import Combine

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
        effect = { transitionPublisher, send in
            transitionPublisher.sink { pair in
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
        effect = { transitionPublisher, _ in
            sink(transitionPublisher)
        }
    }

    public typealias Effect = (TransitionPublisher, @escaping Send) -> AnyCancellable
    public typealias TransitionPublisher = AnyPublisher<Transition<S, A>, Never>
    public typealias Send = (A) -> Void
}

public extension Effect {
    static func effect(_ effect: @escaping Effect) -> Self {
        self.init(effect: effect)
    }

    static func publisher<P: Publisher>(
        _ publisher: @escaping (TransitionPublisher) -> P
    ) -> Self where P.Output == A, P.Failure == Never {
        self.init(publisher: publisher)
    }

    static func sender(_ sender: @escaping (S, A, @escaping Send) -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sender(_ sender: @escaping (S, A, @escaping Send) async -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sink(_ sink: @escaping (TransitionPublisher) -> AnyCancellable) -> Self {
        self.init(sink: sink)
    }
}

public extension Effect {
    // TODO: creators for effect in environment
}
