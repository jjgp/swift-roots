public extension StateContainer {
    private func actionCreator<T>(at keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }

    // swiftlint:disable function_parameter_count identifier_name
    func send(by keyPath: KeyPath<State, Action>) {
        send(actionCreator(at: keyPath))
    }

    func send<A>(by keyPath: KeyPath<State, (A) -> Action>, with a: A) {
        send(actionCreator(at: keyPath)(a))
    }

    func send<A, B>(by keyPath: KeyPath<State, (A, B) -> Action>, with a: A, _ b: B) {
        send(actionCreator(at: keyPath)(a, b))
    }

    func send<A, B, C>(by keyPath: KeyPath<State, (A, B, C) -> Action>, with a: A, _ b: B, _ c: C) {
        send(actionCreator(at: keyPath)(a, b, c))
    }

    func send<A, B, C, D>(creator keyPath: KeyPath<State, (A, B, C, D) -> Action>, with a: A, _ b: B, _ c: C, _ d: D) {
        send(actionCreator(at: keyPath)(a, b, c, d))
    }

    func send<A, B, C, D, E>(
        creator keyPath: KeyPath<State, (A, B, C, D, E) -> Action>,
        with a: A, _ b: B, _ c: C, _ d: D, _ e: E
    ) {
        send(actionCreator(at: keyPath)(a, b, c, d, e))
    }
    // swiftlint:enable function_parameter_count identifier_name
}
