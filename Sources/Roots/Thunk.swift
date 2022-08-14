public struct Thunk<State, Action>: Roots.Action {
    let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public typealias Run = (@escaping Dispatch<Action>, @escaping GetState<State>) -> Void
}

public extension Thunk {
    init(priority: TaskPriority? = nil, run: @escaping AsyncRun) {
        self.run = { dispatch, getState in
            Task(priority: priority) {
                await run(dispatch, getState)
            }
        }
    }

    typealias AsyncRun = (@escaping Dispatch<Action>, @escaping GetState<State>) async -> Void
}
