public extension Middleware {
    static func combine(middlewares: Self...) -> Self {
        .combine(middlewares: middlewares)
    }

    static func combine(middlewares: [Self]) -> Self {
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
}
