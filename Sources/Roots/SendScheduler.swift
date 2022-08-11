public protocol SendScheduler {
    func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>)
}

public final class OneAtATimeSendScheduler: SendScheduler {
    private var isSending = false
    private var sendPendingBuffer: [SendPending] = []

    public init() {}

    public func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>) {
        guard !isSending else {
            sendPendingBuffer.append {
                send(action)
            }
            return
        }

        isSending = true
        send(action)
        while !sendPendingBuffer.isEmpty {
            sendPendingBuffer.swapAt(0, sendPendingBuffer.count - 1)
            sendPendingBuffer.removeLast()()
        }
        isSending = false
    }

    private typealias SendPending = () -> Void
}
