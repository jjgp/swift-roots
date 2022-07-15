import class Combine.AnyCancellable

public func combine<S: State, A: Action>(effects: Effect<S, A>...) -> Effect<S, A> {
    combine(effects: effects)
}

public func combine<S: State, A: Action>(effects: [Effect<S, A>]) -> Effect<S, A> {
    .effect { transitionPublisher in
        effects.map { $0.createEffect(transitionPublisher) }.flatMap { $0 }
    }
}
