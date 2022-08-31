public protocol Dispatcher {
    func receive(action: Action, transmitTo dispatch: @escaping Dispatch)
}
