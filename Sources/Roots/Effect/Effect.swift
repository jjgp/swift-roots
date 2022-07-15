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

    // TODO: should this be an array of artifacts to be managed?
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

public extension Effect {
    static func publisher<P: Publisher>(
        _ effect: @escaping PublisherEffect<P>
    ) -> Self where P.Output == A, P.Failure == Never {
        self.effect { transitionPublisher in [effect(transitionPublisher).toEffectArtifact()] }
    }

    static func publisher<P: Publisher, Environment>(
        of environment: Environment,
        _ effect: @escaping PublisherEffectOfEnvironment<P, Environment>
    ) -> Self where P.Output == A, P.Failure == Never {
        self.effect(of: environment) { transitionPublisher, environment in
            [effect(transitionPublisher, environment).toEffectArtifact()]
        }
    }

    typealias PublisherEffect<P: Publisher> = (TransitionPublisher) -> P
    typealias PublisherEffectOfEnvironment<P: Publisher, Environment> = (TransitionPublisher, Environment) -> P
}

public extension Effect {
    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.effect { transitionPublisher in
            let subject = PassthroughSubject<A, Never>()
            let cancellable = transitionPublisher.sink { transition in
                effect(transition.state, transition.action, subject.send)
            }
            return [cancellable.toEffectArtifact(), subject.toEffectArtifact()]
        }
    }

    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        // TODO: probably opportunity to reduce repeated code
        self.effect { transitionPublisher in
            let subject = PassthroughSubject<A, Never>()
            let cancellable = transitionPublisher.sink { transition in
                Task {
                    await effect(transition.state, transition.action, subject.send)
                }
            }
            return [cancellable.toEffectArtifact(), subject.toEffectArtifact()]
        }
    }

    static func subject<Environment>(of _: Environment, _: @escaping SubjectEffect) -> Self {
        fatalError()
    }

    typealias SubjectEffect = (S, A, Send) -> Void
    typealias AsyncSubjectEffect = (S, A, Send) async -> Void
}

public extension Effect {
    static func sink(_ effect: @escaping SinkEffect) -> Self {
        self.effect { transitionPublisher in [effect(transitionPublisher).toEffectArtifact()] }
    }

    static func sink<Environment>(of environment: Environment, _ effect: @escaping SinkEffectOfEnvironment<Environment>) -> Self {
        self.effect(of: environment) { transitionPublisher, environment in
            [effect(transitionPublisher, environment).toEffectArtifact()]
        }
    }

    typealias SinkEffect = (TransitionPublisher) -> AnyCancellable
    typealias SinkEffectOfEnvironment<Environment> = (TransitionPublisher, Environment) -> AnyCancellable
}

public extension Effect {
    // TODO: test these
    static func void(_ effect: @escaping VoidEffect) -> Self {
        self.effect { transitionPublisher in
            effect(transitionPublisher)
            return []
        }
    }

    static func void<Environment>(of environment: Environment, _ effect: @escaping VoidEffectOfEnvironment<Environment>) -> Self {
        self.effect(of: environment) { transitionPublisher, environment in
            effect(transitionPublisher, environment)
            return []
        }
    }

    typealias VoidEffect = (TransitionPublisher) -> Void
    typealias VoidEffectOfEnvironment<Environment> = (TransitionPublisher, Environment) -> Void
}
