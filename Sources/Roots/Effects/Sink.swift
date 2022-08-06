import Combine

public extension Effect {
    static func sink(_ effect: @escaping SinkEffect) -> Self {
        self.init { transitionPublisher in
            [Artifact](effect(transitionPublisher))
        }
    }

    typealias SinkEffect = (TransitionPublisher) -> AnyCancellable
}

public extension ContextEffect {
    static func sink(_ effect: @escaping SinkEffect) -> Self {
        self.init { context in
            .sink { transitionPublisher in
                effect(transitionPublisher, context)
            }
        }
    }

    typealias SinkEffect = (TransitionPublisher, Context) -> AnyCancellable
}
