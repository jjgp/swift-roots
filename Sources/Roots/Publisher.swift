import Combine

public extension Publisher {
    func filter<S: State>(action: S.Action) -> Publishers.Filter<Self> where Self.Output == ActionPair<S> {
        filter { $0.action == action }
    }

    func map<S: State>(to action: S.Action) -> Publishers.Map<Self, S.Action> where Self.Output == ActionPair<S> {
        map { _ in action }
    }

    func select<S: State, T>(transform: @escaping (S) -> T) -> Publishers.Map<Self, T> where Self.Output == ActionPair<S> {
        map { transform($0.state) }
    }
}
