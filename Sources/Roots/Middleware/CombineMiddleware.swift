func combine<State, Action>(middlewares: Middleware<State, Action>...) -> Middleware<State, Action> {
    combine(middlewares: middlewares)
}

func combine<State, Action>(middlewares: [Middleware<State, Action>]) -> Middleware<State, Action> {
    .init { store in
        { next in
            middlewares.reversed().reduce({ action in
                next(action)
            }) { dispatch, middleware in
                middleware.createDispatch(store)(dispatch)
            }
        }
    }
}
