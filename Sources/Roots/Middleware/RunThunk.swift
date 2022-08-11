public extension Middleware {
    static func runThunk() -> Self {
        .init { store, next in
            { action in
                guard let action = action as? Thunk<State, Action> else {
                    next(action)
                    return
                }

                action.run(store.send(_:)) {
                    store.state
                }
            }
        }
    }
}
