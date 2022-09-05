public final class BarrierDispatcher: Dispatcher {
    private var buffer: [Action] = []
    private var isDispatching = false

    public init() {}
}

public extension BarrierDispatcher {
    func receive(action: Action, transmitTo dispatch: @escaping Dispatch) {
        guard !isDispatching else {
            buffer.append(action)
            return
        }

        isDispatching = true
        dispatch(action)
        var nextDispatch = 0
        while nextDispatch < buffer.count {
            dispatch(buffer[nextDispatch])
            nextDispatch += 1
        }
        buffer.removeAll()
        isDispatching = false
    }
}
