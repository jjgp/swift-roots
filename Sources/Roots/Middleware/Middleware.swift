public struct Middleware<State, Action> {
    let createDispatch: CreateDispatch

    public init(createDispatch: @escaping CreateDispatch) {
        self.createDispatch = createDispatch
    }

    public typealias CreateDispatch = (Store, @escaping Next) -> Dispatch<Action>
    public typealias Next = Dispatch<Action>
    public typealias Store = AnyStateContainer<State, Action>
}
