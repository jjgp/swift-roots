public struct ActionPair<S: State> {
    let state: S
    let action: S.Action
}
