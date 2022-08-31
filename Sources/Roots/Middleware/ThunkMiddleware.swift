public final class ThunkMiddleware<State>: Middleware<State> {
    override public func respond(to action: Action, forwardingTo next: Dispatch) {
        switch action {
        case let action as Thunk<State>:
            action.store = store
            action.run()
        default:
            next(action)
        }
    }
}
