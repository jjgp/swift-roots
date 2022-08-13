public final class CombineMiddleware<State, Action>: Middleware<State, Action> {
    private let middlewares: [Middleware<State, Action>]
    override public var store: AnyStateContainer<State, Action>! {
        didSet {
            middlewares.forEach { middleware in
                middleware.store = store
            }
        }
    }

    public init(middlewares: [Middleware<State, Action>]) {
        self.middlewares = middlewares
    }

    override public func respond(to action: Action, forwardingTo next: Dispatch<Action>) {
        var index = middlewares.endIndex
        var current: Action? = action
        while index >= 0, let action = current {
            middlewares[index].respond(to: action) { next in
                current = next
            }
            index -= 1
        }
    }
}

public extension CombineMiddleware {
    convenience init(middlewares: Middleware<State, Action>...) {
        self.init(middlewares: middlewares)
    }
}
