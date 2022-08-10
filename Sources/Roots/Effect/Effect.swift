import Combine

public struct Effect<State, Action> {
    public let createCauses: CreateCauses

    public init(createCauses: @escaping CreateCauses) {
        self.createCauses = createCauses
    }

    public enum Cause {
        case cancellable(AnyCancellable)
        case publisher(AnyPublisher<Action, Never>)
    }

    public typealias CreateCauses = (TransitionPublisher) -> [Cause]
    public typealias TransitionPublisher = AnyPublisher<Transition<State, Action>, Never>
}

public extension Effect.Cause {
    init(_ cancellable: AnyCancellable) {
        self = .cancellable(cancellable)
    }

    init<P: Publisher>(_ publisher: P) where P.Output == Action, P.Failure == Never {
        self = .publisher(publisher.eraseToAnyPublisher())
    }
}

public extension Array {
    init<State, Action>(
        _ cancellables: AnyCancellable...
    ) where Self.Element == Effect<State, Action>.Cause {
        self.init()
        append(contentsOf: cancellables.map { .init($0) })
    }

    init<P: Publisher, State, Action>(
        cancellables: AnyCancellable...,
        publishers: P...
    ) where Self.Element == Effect<State, Action>.Cause, P.Output == Action, P.Failure == Never {
        self.init()
        append(contentsOf: cancellables.map { .init($0) })
        append(contentsOf: publishers.map { .init($0) })
    }

    init<P: Publisher, State, Action>(
        _ publishers: P...
    ) where Self.Element == Effect<State, Action>.Cause, P.Output == Action, P.Failure == Never {
        self.init()
        append(contentsOf: publishers.map { .init($0) })
    }
}

public extension Effect {
    func apply(
        _ transitionPublisher: TransitionPublisher,
        _ send: @escaping Dispatch<Action>,
        _ collection: inout Set<AnyCancellable>
    ) {
        var publishers = [AnyPublisher<Action, Never>]()
        for artifact in createCauses(transitionPublisher) {
            switch artifact {
            case let .cancellable(cancellable):
                cancellable.store(in: &collection)
            case let .publisher(publisher):
                publishers.append(publisher)
            }
        }
        Publishers.MergeMany(publishers).sink(receiveValue: send).store(in: &collection)
    }
}
