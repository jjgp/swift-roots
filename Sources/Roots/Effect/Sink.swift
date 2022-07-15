import class Combine.AnyCancellable

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
