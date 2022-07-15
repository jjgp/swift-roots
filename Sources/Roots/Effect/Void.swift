public extension Effect {
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
