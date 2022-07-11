import Combine

public extension Publisher {
    func filter<S: State, A: Action>(action: A) -> Publishers.Filter<Self> where Self.Output == Transition<S, A> {
        filter { $0.action == action }
    }

    func map<S: State, A: Action>(to action: A) -> Publishers.Map<Self, A> where Self.Output == Transition<S, A> {
        map { _ in action }
    }

    func select<S: State, A: Action, T: State>(transform: @escaping (S) -> T) -> Publishers.Map<Self, T> where Self.Output == Transition<S, A> {
        map { transform($0.state) }
    }
}
