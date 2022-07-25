import Combine

public struct Effect<S: State, Action> {
    let createEffect: CreateEffect

    public init(createEffect: @escaping CreateEffect) {
        self.createEffect = createEffect
    }

    public enum Artifact {
        case cancellable(AnyCancellable)
        case publisher(AnyPublisher<Action, Never>)
    }

    public typealias CreateEffect = (TransitionPublisher) -> [Artifact]
    public typealias TransitionPublisher = AnyPublisher<Transition<S, Action>, Never>
}

public extension AnyCancellable {
    func toEffectArtifact<S: State, Action>() -> Effect<S, Action>.Artifact {
        .cancellable(self)
    }
}

public extension Publisher {
    func toEffectArtifact<S: State, Action>() -> Effect<S, Action>.Artifact where Self.Output == Action, Self.Failure == Never {
        .publisher(eraseToAnyPublisher())
    }
}

public extension Effect {
    func apply(
        _ transitionPublisher: TransitionPublisher,
        _ send: @escaping Send,
        _ collection: inout Set<AnyCancellable>
    ) {
        var publishers = [AnyPublisher<Action, Never>]()
        for artifact in createEffect(transitionPublisher) {
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
