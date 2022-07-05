public typealias Reducer<S: State> = (inout S, S.Action) -> S
