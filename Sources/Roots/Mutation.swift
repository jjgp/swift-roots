public typealias Mutation<State> = (inout State, Action) -> Void
