public struct Thunk<State> {
    let run: Run

    public init(run: @escaping Run) {
        self.run = run
    }

    public typealias Run = (Dispatch<Action>, () -> State) -> Void
}
