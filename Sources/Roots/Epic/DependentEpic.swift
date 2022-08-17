import Combine

public struct DependentEpic<State, Action, Dependencies> {
    public let createEpic: CreateEpic

    public init<P: Publisher>(createPublisher: @escaping (States, Actions, Dependencies) -> P) where P.Failure == Never, P.Output == Action {
        createEpic = { dependencies in
            Epic { states, actions in
                createPublisher(states, actions, dependencies)
            }
        }
    }

    public typealias Actions = Epic.Actions
    public typealias CreateEpic = (Dependencies) -> Epic
    public typealias Epic = Roots.Epic<State, Action>
    public typealias States = Epic.States
}
