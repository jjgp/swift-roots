import Combine

public extension Effect {
    static func combine(effects: Self...) -> Self {
        combine(effects: effects)
    }

    static func combine(effects: [Self]) -> Self {
        .init { transitionPublisher in
            effects.flatMap { effect in
                effect.createCauses(transitionPublisher)
            }
        }
    }

    static func combine<Context>(
        context: Context,
        and contextEffects: ContextEffect<State, Action, Context>...
    ) -> Self {
        combine(context: context, and: contextEffects)
    }

    static func combine<Context>(
        context: Context,
        and contextEffects: [ContextEffect<State, Action, Context>]
    ) -> Self {
        combine(effects: contextEffects.map {
            $0.createEffect(context)
        })
    }
}
