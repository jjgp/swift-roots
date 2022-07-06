import Combine

public struct Effect<S: State> {
    let effect: (CombineLatestPublisher, @escaping Send) -> AnyCancellable

    public init<P: Publisher>(
        publisher: @escaping (CombineLatestPublisher) -> P
    ) where P.Output == S.Action, P.Failure == Never {
        effect = {
            publisher($0)
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public init(sink: @escaping (CombineLatestPublisher) -> AnyCancellable) {
        effect = { combineLatestPublisher, _ in
            sink(combineLatestPublisher)
        }
    }

    public init(transform: @escaping (S, S.Action) -> S.Action?) {
        effect = {
            $0
                .map { state, action in
                    transform(state, action)
                }
                .compactMap { $0 }
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public init(transform: @escaping (S, S.Action) async -> S.Action?) {
        effect = {
            $0
                .flatMap { state, action in
                    Future { promise in
                        Task {
                            let action = await transform(state, action)
                            promise(.success(action))
                        }
                    }
                }
                .compactMap { $0 }
                .eraseToAnyPublisher()
                .sink(receiveValue: $1)
        }
    }

    public typealias CombineLatestPublisher = AnyPublisher<(S, S.Action), Never>
    typealias Send = (S.Action) -> Void
}
