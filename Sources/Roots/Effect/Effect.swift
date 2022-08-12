import Combine

public struct Effect<State, Action> {
    public let createPublisher: CreatePublisher

    public init<P: Publisher>(createPublisher: @escaping (States, Actions) -> P) where P.Failure == Never, P.Output == Action {
        self.createPublisher = { states, actions in
            createPublisher(states, actions).eraseToAnyPublisher()
        }
    }

    public typealias Actions = AnyPublisher<Action, Never>
    public typealias CreatePublisher = (States, Actions) -> Actions
    public typealias States = AnyPublisher<State, Never>
}
