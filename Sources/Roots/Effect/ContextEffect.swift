import Combine

public struct ContextEffect<State, Action, Context> {
    public let createEffect: CreateEffect

    public init<P: Publisher>(createPublisher: @escaping (States, Actions, Context) -> P) where P.Failure == Never, P.Output == Action {
        createEffect = { context in
            Effect { states, actions in
                createPublisher(states, actions, context)
            }
        }
    }

    public typealias Actions = Effect.Actions
    public typealias CreateEffect = (Context) -> Effect
    public typealias Effect = Roots.Effect<State, Action>
    public typealias States = Effect.States
}
