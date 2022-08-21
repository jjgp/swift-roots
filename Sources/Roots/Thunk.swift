open class Thunk<State, Action> {
    public var store: AnyStateContainer<State, Action>!

    public init() {}

    open func run() {}
}

open class AsyncThunk<State, Action>: Thunk<State, Action> {
    let priority: TaskPriority?

    public init(priority: TaskPriority? = nil) {
        self.priority = priority
    }

    override public func run() {
        Task(priority: priority) {
            await run()
        }
    }

    open func run() async {}
}

public final class BlockThunk<State, Action>: Thunk<State, Action> {
    let block: Block

    public init(block: @escaping Block) {
        self.block = block
    }

    public init(priority: TaskPriority? = nil, block: @escaping AsyncBlock) {
        self.block = { dispatch, getState in
            Task(priority: priority) {
                await block(dispatch, getState)
            }
        }
    }

    override public func run() {
        block(store.send(_:)) {
            self.store.state
        }
    }

    public typealias AsyncBlock = (@escaping Dispatch<Action>, @escaping () -> State) async -> Void
    public typealias Block = (@escaping Dispatch<Action>, @escaping () -> State) -> Void
}

public extension Store {
    func run(thunk: Thunk<State, Action>) {
        thunk.store = toAnyStateContainer()
        thunk.run()
    }
}
