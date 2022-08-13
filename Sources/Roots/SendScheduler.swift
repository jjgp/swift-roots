public protocol SendScheduler {
    func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>)
}

public final class BufferedRecursionSendScheduler: SendScheduler {
    var isSending = false
    var sendPendingBuffer: [SendPending] = []

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

    typealias SendPending = () -> Void
}
