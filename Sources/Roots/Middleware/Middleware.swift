open class Middleware<State, Action> {
    public internal(set) var store: AnyStateContainer<State, Action>!

    open func respond(to _: Action, forwardingTo _: Dispatch<Action>) {}
}
