import Combine

public struct Effect<S: State> {
    let effect: (StatePublisher, ActionPublisher, @escaping Send) -> AnyCancellable

    public init<P: Publisher>(
        publisher: @escaping (StatePublisher, ActionPublisher) -> P
    ) where P.Output == S.Action, P.Failure == Never {
        effect = {
            publisher($0, $1)
                .eraseToAnyPublisher()
                .sink(receiveValue: $2)
        }
    }

    public init(sink: @escaping (StatePublisher, ActionPublisher) -> AnyCancellable) {
        effect = { actionPublisher, statePublisher, _ in
            sink(actionPublisher, statePublisher)
        }
    }

    public init(transform: @escaping (S, S.Action) -> S.Action) {
        effect = {
            $0
                .combineLatest($1, transform)
                .eraseToAnyPublisher()
                .sink(receiveValue: $2)
        }
    }

    public init(transform: @escaping (S, S.Action) async -> S.Action) {
        effect = {
            $0
                .combineLatest($1)
                .flatMap { state, action in
                    Future { promise in
                        Task {
                            let action = await transform(state, action)
                            promise(.success(action))
                        }
                    }
                }
                .eraseToAnyPublisher()
                .sink(receiveValue: $2)
        }
    }

    public typealias ActionPublisher = AnyPublisher<S.Action, Never>
    public typealias StatePublisher = AnyPublisher<S, Never>
    typealias Send = (S.Action) -> Void
}
