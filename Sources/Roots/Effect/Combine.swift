import class Combine.AnyCancellable

// public func combine<S: State, A: Action>(effects: Effect<S, A>...) -> Effect<S, A> {
//    combine(effects: effects)
// }
//
// public func combine<S: State, A: Action>(effects: [Effect<S, A>]) -> Effect<S, A> {
//    Effect(effect: { transitionPublisher, send in
//        let cancellables = effects.map { $0.effect(transitionPublisher, send) }
//        return AnyCancellable {
//            cancellables.forEach {
//                $0.cancel()
//            }
//        }
//    })
// }
//
// public typealias EffectInEnvironment<S: State, A: Action, Environment> = (Environment) -> Effect<S, A>.Effect
//
// public func combine<S: State, A: Action, Environment>(environment _: Environment, effects _: EffectInEnvironment<S, A, Environment>...) {
//    // TODO:
// }
//
// public func combine<S: State, A: Action, Environment>(environment _: Environment, effects _: [EffectInEnvironment<S, A, Environment>]) {
//    // TODO:
// }
