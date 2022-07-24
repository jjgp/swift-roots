import Combine

public func combine<S: State, A: Action>(effects: Effect<S, A>...) -> Effect<S, A> {
    combine(effects: effects)
}

public func combine<S: State, A: Action>(effects: [Effect<S, A>]) -> Effect<S, A> {
    .init { transitionPublisher in
        effects.flatMap { effect in
            effect.createEffect(transitionPublisher)
        }
    }
}

public func combine<S: State, A: Action, Context>(
    context: Context,
    with contextEffects: ContextEffect<S, A, Context>...
) -> Effect<S, A> {
    combine(context: context, with: contextEffects)
}

public func combine<S: State, A: Action, Context>(
    context: Context,
    with contextEffects: [ContextEffect<S, A, Context>]
) -> Effect<S, A> {
    combine(context: contextEffects.map {
        $0.createEffect(context)
    })
}
