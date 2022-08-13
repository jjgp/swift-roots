open class Middleware<State, Action> {
    public var store: AnyStateContainer<State, Action>!

    public init() {}

    open func respond(to _: Action, forwardingTo _: Dispatch<Action>) {}
}
