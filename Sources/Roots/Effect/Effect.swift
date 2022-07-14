import Combine

public struct Effect<S: State, A: Action> {
    private let createEffect: CreateEffect

    public init(createEffect: @escaping CreateEffect) {
        self.createEffect = createEffect
    }

    public init<P: Publisher>(publisher: P) where P.Output == A, P.Failure == Never {
        createEffect = { _ in .publisher(publisher.eraseToAnyPublisher()) }
    }

    public enum Artifacts {
        case both(AnyCancellable, AnyPublisher<A, Never>)
        case cancellable(AnyCancellable)
        case none // TODO: this is if the artifiacts should be managed outside of the store lifecycle
        case publisher(AnyPublisher<A, Never>)
    }

    public typealias CreateEffect = (TransitionPublisher) -> Artifacts
    public typealias TransitionPublisher = AnyPublisher<Transition<S, A>, Never>
}

extension Effect.Artifacts {
    var artifacts: (AnyCancellable?, AnyPublisher<A, Never>?) {
        switch self {
        case let .both(cancellable, publisher):
            return (cancellable, publisher)
        case let .cancellable(cancellable):
            return (cancellable, nil)
        case let .publisher(publisher):
            return (nil, publisher)
        case .none:
            return (nil, nil)
        }
    }
}

extension Effect {
    func createEffect(
        _ transitionPublisher: TransitionPublisher,
        _ send: @escaping Send,
        _ collection: inout Set<AnyCancellable>
    ) {
        let (cancellable, publisher) = createEffect(transitionPublisher).artifacts
        publisher?.sink(receiveValue: send).store(in: &collection)
        cancellable?.store(in: &collection)
    }
}

public extension Effect {
    static func effect(createEffect: @escaping CreateEffect) -> Self {
        self.init(createEffect: createEffect)
    }

    static func effect<Environment>(
        of environment: Environment,
        createEffectOfEnvironment: @escaping CreateEffectOfEnvironment<Environment>
    ) -> Self {
        effect { transitionPublisher in
            createEffectOfEnvironment(transitionPublisher, environment)
        }
    }

    static func effect<P: Publisher>(publisher: P) -> Self where P.Output == A, P.Failure == Never {
        self.init(publisher: publisher)
    }

    typealias CreateEffectOfEnvironment<Environment> = (TransitionPublisher, Environment) -> Artifacts
}

public extension Effect {
    static func subject(subjectEffect: @escaping SubjectEffect) -> Self {
        effect { transitionPublisher in
            let subject = PassthroughSubject<A, Never>()
            let cancellable = transitionPublisher.sink { transition in
                subjectEffect(transition.state, transition.action, subject.send)
            }
            return .both(cancellable, subject.eraseToAnyPublisher())
        }
    }

    static func subject<Environment>(of _: Environment, _: @escaping SubjectEffect) -> Self {
        fatalError()
    }

    typealias Send = (A) -> Void
    typealias SubjectEffect = (S, A, Send) -> Void
    typealias AsyncSubjectEffect = (S, A, Send) async -> Void
}

public extension Effect {
    static func sink(_ effect: @escaping SinkEffect) -> Self {
        self.effect { transitionPublisher in .cancellable(effect(transitionPublisher)) }
    }

    static func sink<Environment>(of environment: Environment, _ effect: @escaping SinkEffectOfEnvironment<Environment>) -> Self {
        self.effect(of: environment) { transitionPublisher, environment in
            .cancellable(effect(transitionPublisher, environment))
        }
    }

    typealias SinkEffect = (TransitionPublisher) -> AnyCancellable
    typealias SinkEffectOfEnvironment<Environment> = (TransitionPublisher, Environment) -> AnyCancellable
}
