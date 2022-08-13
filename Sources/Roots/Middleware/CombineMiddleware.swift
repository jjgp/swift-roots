// public extension Middleware {
//    static func combine(middlewares: Self...) -> Self {
//        .combine(middlewares: middlewares)
//    }
//
//    static func combine(middlewares: [Self]) -> Self {
//        .init { store, next in
//            middlewares.reversed().reduce(next) { dispatch, middleware in
//                middleware.createDispatch(store, dispatch)
//            }
//        }
//    }
// }
