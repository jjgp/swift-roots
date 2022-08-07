public extension StateContainer {
    private func actionCreator<T>(at keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }

    // swiftlint:disable function_parameter_count identifier_name
    func send(creator keyPath: KeyPath<State, Action>) {
        send(actionCreator(at: keyPath))
    }

    func send<A>(creator keyPath: KeyPath<State, (A) -> Action>, passing a: A) {
        send(actionCreator(at: keyPath)(a))
    }

    func send<A, B>(creator keyPath: KeyPath<State, (A, B) -> Action>, passing a: A, _ b: B) {
        send(actionCreator(at: keyPath)(a, b))
    }

    func send<A, B, C>(creator keyPath: KeyPath<State, (A, B, C) -> Action>, passing a: A, _ b: B, _ c: C) {
        send(actionCreator(at: keyPath)(a, b, c))
    }

    func send<A, B, C, D>(creator keyPath: KeyPath<State, (A, B, C, D) -> Action>, passing a: A, _ b: B, _ c: C, _ d: D) {
        send(actionCreator(at: keyPath)(a, b, c, d))
    }

    func send<A, B, C, D, E>(
        creator keyPath: KeyPath<State, (A, B, C, D, E) -> Action>,
        passing a: A, _ b: B, _ c: C, _ d: D, _ e: E
    ) {
        send(actionCreator(at: keyPath)(a, b, c, d, e))
    }
    // swiftlint:enable function_parameter_count identifier_name
}
