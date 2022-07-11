public typealias Reducer<S: State, A: Action> = (inout S, A) -> S
