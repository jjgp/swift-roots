open class Thunk<State>: Action {
    public var store: AnyStateContainer<State>!

    public init() {}

    open func run() {}
}
