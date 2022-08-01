import Combine

public func combine<State, Action>(effects: Effect<State, Action>...) -> Effect<State, Action> {
    combine(effects: effects)
}

public func combine<State, Action>(effects: [Effect<State, Action>]) -> Effect<State, Action> {
    .init { transitionPublisher in
        effects.flatMap { effect in
            effect.createArtifacts(transitionPublisher)
        }
    }
}

public func combine<State, Action, Context>(
    context: Context,
    with contextEffects: ContextEffect<State, Action, Context>...
) -> Effect<State, Action> {
    combine(context: context, with: contextEffects)
}

public func combine<State, Action, Context>(
    context: Context,
    with contextEffects: [ContextEffect<State, Action, Context>]
) -> Effect<State, Action> {
    combine(effects: contextEffects.map {
        $0.createEffect(context)
    })
}
