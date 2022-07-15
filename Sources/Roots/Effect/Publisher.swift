import protocol Combine.Publisher

public extension Effect {
    static func publisher<P: Publisher>(
        _ effect: @escaping PublisherEffect<P>
    ) -> Self where P.Output == A, P.Failure == Never {
        self.effect { transitionPublisher in
            [effect(transitionPublisher).toEffectArtifact()]
        }
    }

    static func publisher<P: Publisher, Environment>(
        of environment: Environment,
        _ effect: @escaping PublisherEffectOfEnvironment<P, Environment>
    ) -> Self where P.Output == A, P.Failure == Never {
        self.publisher { transitionPublisher in
            effect(transitionPublisher, environment)
        }
    }

    typealias PublisherEffect<P: Publisher> = (TransitionPublisher) -> P
    typealias PublisherEffectOfEnvironment<P: Publisher, Environment> = (TransitionPublisher, Environment) -> P
}
