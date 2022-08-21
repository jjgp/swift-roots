public struct Thunk<State, Action> {
    let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public typealias Run = (@escaping Dispatch<Action>, @escaping () -> State) -> Void
}

public extension Thunk {
    init(priority: TaskPriority? = nil, run: @escaping AsyncRun) {
        self.run = { dispatch, getState in
            Task(priority: priority) {
                await run(dispatch, getState)
            }
        }
    }

    typealias AsyncRun = (@escaping Dispatch<Action>, @escaping () -> State) async -> Void
}

public extension Store {
    func run(thunk: Thunk<State, Action>) {
        let store = toAnyStateContainer()
        thunk.run(store.send(_:)) {
            store.state
        }
    }
}
