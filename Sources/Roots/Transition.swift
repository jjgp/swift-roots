public struct Transition<S: State, A: Action> {
    let state: S
    let action: A
}
