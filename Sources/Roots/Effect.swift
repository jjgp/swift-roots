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

    public init(sink: @escaping (StateActionPairPublisher) -> AnyCancellable) {
        effect = { combineLatestPublisher, _ in
            sink(combineLatestPublisher)
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

    public typealias StateActionPairPublisher = AnyPublisher<(S, S.Action), Never>
    public typealias Send = (S.Action) -> Void
}

extension Effect {
    static var noEffect: Self {
        Effect(sink: { $0.sink(receiveValue: { _ in }) })
    }
}
