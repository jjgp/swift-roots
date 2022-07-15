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
