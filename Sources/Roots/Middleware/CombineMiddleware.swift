public final class CombineMiddleware<State, Action>: Middleware<State, Action> {
    private let middlewares: [Middleware<State, Action>]
    override public var store: AnyStateContainer<State, Action>! {
        didSet {
            middlewares.forEach { middleware in
                middleware.store = store
            }
        }
    }

    public init(_ middlewares: [Middleware<State, Action>]) {
        self.middlewares = middlewares
    }

    override public func respond(to action: Action, forwardingTo next: Dispatch<Action>) {
        var current: Action! = action

        for middleware in middlewares.reversed() {
            guard let action = current else {
                return
            }

            middleware.respond(to: action) { next in
                current = next
            }
        }

        next(current)
    }
}

public extension CombineMiddleware {
    convenience init(_ middlewares: Middleware<State, Action>...) {
        self.init(middlewares)
    }
}
