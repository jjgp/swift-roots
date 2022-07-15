import Combine

public struct Effect<S: State, A: Action> {
    let createEffect: CreateEffect

    public init(createEffect: @escaping CreateEffect) {
        self.createEffect = createEffect
    }

    public enum Artifact {
        case cancellable(AnyCancellable)
        case publisher(AnyPublisher<A, Never>)
    }

    public typealias CreateEffect = (TransitionPublisher) -> [Artifact]
    public typealias TransitionPublisher = AnyPublisher<Transition<S, A>, Never>
}

public extension AnyCancellable {
    func toEffectArtifact<S: State, A: Action>() -> Effect<S, A>.Artifact {
        .cancellable(self)
    }
}

public extension Publisher {
    func toEffectArtifact<S: State, A: Action>() -> Effect<S, A>.Artifact where Self.Output == A, Self.Failure == Never {
        .publisher(eraseToAnyPublisher())
    }
}

extension Effect {
    func apply(
        _ transitionPublisher: TransitionPublisher,
        _ send: @escaping Send,
        _ collection: inout Set<AnyCancellable>
    ) {
        var publishers = [AnyPublisher<A, Never>]()
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

    public typealias Send = (A) -> Void
}

public extension Effect {
    static func effect(createEffect: @escaping CreateEffect) -> Self {
        self.init(createEffect: createEffect)
    }

    static func effect<Environment>(
        of environment: Environment,
        createEffectOfEnvironment: @escaping CreateEffectOfEnvironment<Environment>
    ) -> Self {
        self.init { transitionPublisher in
            createEffectOfEnvironment(transitionPublisher, environment)
        }
    }

    typealias CreateEffectOfEnvironment<Environment> = (TransitionPublisher, Environment) -> [Artifact]
}
