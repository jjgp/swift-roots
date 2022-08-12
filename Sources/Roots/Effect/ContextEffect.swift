public struct ContextEffect<State, Action, Context> {
    public let createEffect: CreateEffect

    public init(createEffect: @escaping CreateEffect) {
        self.createEffect = createEffect
    }

    public typealias CreateEffect = (Context) -> Effect
    public typealias Effect = Roots.Effect<State, Action>
}
