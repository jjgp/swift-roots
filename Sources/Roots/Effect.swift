import Combine

public struct Effect<S: State> {
    let effect: (ActionPairPublisher, @escaping Send) -> AnyCancellable

    public init<P: Publisher>(
        publisher: @escaping (ActionPairPublisher) -> P
    ) where P.Output == S.Action, P.Failure == Never {
        effect = {
            publisher($0)
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public init(sender: @escaping (S, S.Action, @escaping Send) -> Void) {
        effect = { actionPairPublisher, send in
            actionPairPublisher.sink { pair in
                sender(pair.state, pair.action, send)
            }
        }
    }

    public init(sender: @escaping (S, S.Action, @escaping Send) async -> Void) {
        self.init { state, action, send in
            Task {
                await sender(state, action, send)
            }
        }
    }

    public init(sink: @escaping (ActionPairPublisher) -> AnyCancellable) {
        effect = { actionPairPublisher, _ in
            sink(actionPairPublisher)
        }
    }

    public typealias ActionPairPublisher = AnyPublisher<ActionPair<S>, Never>
    // TODO: instead of passing a send maybe the publisher is merged with the Store's subject
    public typealias Send = (S.Action) -> Void
}

public extension Effect {
    static func publisher<P: Publisher>(
        publisher: @escaping (ActionPairPublisher) -> P
    ) -> Self where P.Output == S.Action, P.Failure == Never {
        self.init(publisher: publisher)
    }

    static func sender(sender: @escaping (S, S.Action, @escaping Send) -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sender(sender: @escaping (S, S.Action, @escaping Send) async -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sink(sink: @escaping (ActionPairPublisher) -> AnyCancellable) -> Self {
        self.init(sink: sink)
    }
}

extension Effect {
    static var noEffect: Self {
        Effect(sink: { $0.sink(receiveValue: { _ in }) })
    }
}
