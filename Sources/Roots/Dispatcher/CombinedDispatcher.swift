public final class CombinedDispatcher: Dispatcher {
    private let dispatchers: [Dispatcher]

    public init(_ dispatchers: [Dispatcher]) {
        self.dispatchers = dispatchers
    }
}

public extension CombinedDispatcher {
    convenience init(_ dispatchers: Dispatcher...) {
        self.init(dispatchers)
    }
}

public extension CombinedDispatcher {
    func receive(action: Action, transmitTo dispatch: @escaping Dispatch) {
        var dispatch = dispatch

        for dispatcher in dispatchers.reversed() {
            dispatch = { [dispatch] action in
                dispatcher.receive(action: action, transmitTo: dispatch)
            }
        }

        dispatch(action)
    }
}
