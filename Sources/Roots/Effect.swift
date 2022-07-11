import Combine

public struct Effect<S: State, A: Action> {
    let effect: (TransitionPublisher, @escaping Send) -> AnyCancellable

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

    public typealias TransitionPublisher = AnyPublisher<Transition<S, A>, Never>
    // TODO: instead of passing a send maybe the publisher is merged with the Store's subject
    public typealias Send = (A) -> Void
}

public extension Effect {
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

extension Effect {
    static var noEffect: Self {
        Effect(sink: { $0.sink(receiveValue: { _ in }) })
    }
}
