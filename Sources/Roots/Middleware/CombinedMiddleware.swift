public final class CombinedMiddleware<State>: Middleware<State> {
    private let middlewares: [Middleware<State>]
    override public var store: AnyStateContainer<State>! {
        didSet {
            middlewares.forEach { middleware in
                middleware.store = store
            }
        }
    }

    public init(_ middlewares: [Middleware<State>]) {
        self.middlewares = middlewares
    }

    override public func respond(to action: Action, forwardingTo next: Dispatch) {
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

public extension CombinedMiddleware {
    convenience init(_ middlewares: Middleware<State>...) {
        self.init(middlewares)
    }
}
