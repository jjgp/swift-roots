public final class RunThunk<State, Action>: Middleware<State, Action> {
    override public func respond(to action: Action, forwardingTo next: Dispatch<Action>) {
        switch action {
        case let action as Thunk<State, Action>:
            action.run(store.send(_:)) {
                self.store.state
            }
        default:
            next(action)
        }
    }
}
