import Combine

public extension Effect {
    static func publisher<P: Publisher>(
        _ effect: @escaping PublisherEffect<P>
    ) -> Self where P.Output == Action, P.Failure == Never {
        self.init { transitionPublisher in
            [Cause](effect(transitionPublisher))
        }
    }

    typealias PublisherEffect<P: Publisher> = (TransitionPublisher) -> P
}

public extension ContextEffect {
    static func publisher<P: Publisher>(
        _ effect: @escaping PublisherEffect<P>
    ) -> Self where P.Output == Action, P.Failure == Never {
        self.init { context in
            .publisher { transitionPublisher in
                effect(transitionPublisher, context)
            }
        }
    }

    typealias PublisherEffect<P: Publisher> = (TransitionPublisher, Context) -> P
}
