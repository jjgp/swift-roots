import Combine

public func combine<S: State, Action>(effects: Effect<S, Action>...) -> Effect<S, Action> {
    combine(effects: effects)
}

public func combine<S: State, Action>(effects: [Effect<S, Action>]) -> Effect<S, Action> {
    .init { transitionPublisher in
        effects.flatMap { effect in
            effect.createEffect(transitionPublisher)
        }
    }
}

public func combine<S: State, Action, Context>(
    context: Context,
    with contextEffects: ContextEffect<S, Action, Context>...
) -> Effect<S, Action> {
    combine(context: context, with: contextEffects)
}

public func combine<S: State, Action, Context>(
    context: Context,
    with contextEffects: [ContextEffect<S, Action, Context>]
) -> Effect<S, Action> {
    combine(effects: contextEffects.map {
        $0.createEffect(context)
    })
}
