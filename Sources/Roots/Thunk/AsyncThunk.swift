public struct AsyncThunk<State> {
    let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public typealias Run = (Dispatch<Action>, () -> State) async -> Void
}
