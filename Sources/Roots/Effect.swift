import Combine

public struct Effect<State, Action> {
    public let createArtifacts: CreateArtifacts

    public init(createArtifacts: @escaping CreateArtifacts) {
        self.createArtifacts = createArtifacts
    }

    public enum Artifact {
        case cancellable(AnyCancellable)
        case publisher(AnyPublisher<Action, Never>)
    }

    public typealias CreateArtifacts = (TransitionPublisher) -> [Artifact]
    public typealias TransitionPublisher = AnyPublisher<Transition<State, Action>, Never>
}

public extension Effect.Artifact {
    init(_ cancellable: AnyCancellable) {
        self = .cancellable(cancellable)
    }

    init<P: Publisher>(_ publisher: P) where P.Output == Action, P.Failure == Never {
        self = .publisher(publisher.eraseToAnyPublisher())
    }
}

public extension AnyCancellable {
    func toEffectArtifact<State, Action>() -> Effect<State, Action>.Artifact {
        .init(self)
    }
}

public extension Publisher {
    func toEffectArtifact<State, Action>() -> Effect<State, Action>.Artifact where Self.Output == Action, Self.Failure == Never {
        .init(self)
    }
}

public extension Array {
    init<State, Action>(
        _ cancellables: AnyCancellable...
    ) where Self.Element == Effect<State, Action>.Artifact {
        self.init()
        append(contentsOf: cancellables.map { $0.toEffectArtifact() })
    }

    init<P: Publisher, State, Action>(
        cancellables: AnyCancellable...,
        publishers: P...
    ) where Self.Element == Effect<State, Action>.Artifact, P.Output == Action, P.Failure == Never {
        self.init()
        append(contentsOf: cancellables.map { $0.toEffectArtifact() })
        append(contentsOf: publishers.map { $0.toEffectArtifact() })
    }

    init<P: Publisher, State, Action>(
        _ publishers: P...
    ) where Self.Element == Effect<State, Action>.Artifact, P.Output == Action, P.Failure == Never {
        self.init()
        append(contentsOf: publishers.map { $0.toEffectArtifact() })
    }
}

public extension Effect {
    func apply(
        _ transitionPublisher: TransitionPublisher,
        _ send: @escaping Send,
        _ collection: inout Set<AnyCancellable>
    ) {
        var publishers = [AnyPublisher<Action, Never>]()
        for artifact in createArtifacts(transitionPublisher) {
            switch artifact {
            case let .cancellable(cancellable):
                cancellable.store(in: &collection)
            case let .publisher(publisher):
                publishers.append(publisher)
            }
        }
        Publishers.MergeMany(publishers).sink(receiveValue: send).store(in: &collection)
    }

    typealias Send = (Action) -> Void
}
