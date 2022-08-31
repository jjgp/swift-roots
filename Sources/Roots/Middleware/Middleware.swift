open class Middleware<State> {
    public var store: AnyStateContainer<State>!

    public init() {}

    open func respond(to _: Action, forwardingTo _: Dispatch) {}
}
