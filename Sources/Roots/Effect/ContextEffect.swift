public struct ContextEffect<S: State, A: Action, Context> {
    let createEffect: CreateEffect

    public init(createEffect: @escaping CreateEffect) {
        self.createEffect = createEffect
    }

    public typealias CreateEffect = (Context) -> Effect
    public typealias Effect = Roots.Effect<S, A>
    public typealias Send = Effect.Send
    public typealias TransitionPublisher = Effect.TransitionPublisher
}
