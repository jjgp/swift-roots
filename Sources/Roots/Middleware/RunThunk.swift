public extension Middleware {
    static func runThunk() -> Self {
        .init { store, next in
            { action in
                switch action {
                case let action as Thunk<State, Action>:
                    action.run(store.send(_:)) {
                        store.state
                    }
                default:
                    next(action)
                }
            }
        }
    }
}
