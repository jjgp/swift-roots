import Combine

public struct Effect<S: State> {
    let effect: (StateActionPairPublisher, @escaping Send) -> AnyCancellable

    public init<P: Publisher>(
        publisher: @escaping (StateActionPairPublisher) -> P
    ) where P.Output == S.Action, P.Failure == Never {
        effect = {
            publisher($0)
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public init(sender: @escaping (S, S.Action, @escaping Send) -> Void) {
        effect = { stateActionPair, send in
            stateActionPair.sink { state, action in
                sender(state, action, send)
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

    public init(sink: @escaping (StateActionPairPublisher) -> AnyCancellable) {
        effect = { combineLatestPublisher, _ in
            sink(combineLatestPublisher)
        }
    }

    public typealias StateActionPairPublisher = AnyPublisher<(S, S.Action), Never>
    public typealias Send = (S.Action) -> Void
}

public extension Effect {
    static func publisher<P: Publisher>(
        publisher: @escaping (StateActionPairPublisher) -> P
    ) -> Self where P.Output == S.Action, P.Failure == Never {
        self.init(publisher: publisher)
    }

    static func sender(sender: @escaping (S, S.Action, @escaping Send) -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sender(sender: @escaping (S, S.Action, @escaping Send) async -> Void) -> Self {
        self.init(sender: sender)
    }

    static func sink(sink: @escaping (StateActionPairPublisher) -> AnyCancellable) -> Self {
        self.init(sink: sink)
    }
}

extension Effect {
    static var noEffect: Self {
        Effect(sink: { $0.sink(receiveValue: { _ in }) })
    }
}
