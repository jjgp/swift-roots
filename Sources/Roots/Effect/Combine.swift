import class Combine.AnyCancellable

public func combine<S: State, A: Action>(effects: Effect<S, A>...) -> Effect<S, A> {
    combine(effects: effects)
}

public func combine<S: State, A: Action>(effects: [Effect<S, A>]) -> Effect<S, A> {
    .effect { transitionPublisher in
        effects.flatMap { effect in
            effect.createEffect(transitionPublisher)
        }
    }
}

public func combine<S: State, A: Action, Environment>(
    environment: Environment,
    with dependentEffectsofEnvironment: (Environment) -> Effect<S, A>...
) -> Effect<S, A> {
    combine(environment: environment, with: dependentEffectsofEnvironment)
}

public func combine<S: State, A: Action, Environment>(
    environment: Environment,
    with dependentEffectsOfEnvironment: [(Environment) -> Effect<S, A>]
) -> Effect<S, A> {
    combine(effects: dependentEffectsOfEnvironment.map {
        $0(environment)
    })
}
