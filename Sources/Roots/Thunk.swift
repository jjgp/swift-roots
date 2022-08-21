open class Thunk<State, Action> {
    public var store: AnyStateContainer<State, Action>!

    public init() {}

    open func run() {}
}

open class AsyncThunk<State, Action> {
    public var store: AnyStateContainer<State, Action>!

    public init() {}

    open func run() async {}
}

public extension Store {
    func run(thunk: Thunk<State, Action>) {
        thunk.store = toAnyStateContainer()
        thunk.run()
    }

    func run(thunk operation: (@escaping Dispatch<Action>, @escaping () -> State) -> Void) {
        let store = toAnyStateContainer()
        operation(store.send(_:)) { store.state }
    }

    func run(thunk: AsyncThunk<State, Action>) async {
        thunk.store = toAnyStateContainer()
        await thunk.run()
    }

    func run(thunk operation: (@escaping Dispatch<Action>, @escaping () -> State) async -> Void) async {
        let store = toAnyStateContainer()
        await operation(store.send(_:)) { store.state }
    }
}
