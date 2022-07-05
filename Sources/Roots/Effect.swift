import Combine

public struct Effect<S: State> {
    let effect: (ActionPublisher, StatePublisher, @escaping Send) -> AnyCancellable

    public init<P: Publisher>(
        publisher: @escaping (ActionPublisher, StatePublisher) -> P
    ) where P.Output == S.Action, P.Failure == Never {
        effect = {
            publisher($0, $1)
                .eraseToAnyPublisher()
                .sink(receiveValue: $2)
        }
    }

    public init(sink: @escaping (ActionPublisher, StatePublisher) -> AnyCancellable) {
        effect = { actionPublisher, statePublisher, _ in
            sink(actionPublisher, statePublisher)
        }
    }

    public typealias ActionPublisher = AnyPublisher<S.Action, Never>
    public typealias StatePublisher = AnyPublisher<S, Never>
    typealias Send = (S.Action) -> Void
}
