public protocol SendScheduler {
    func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>)
}

public final class BufferedRecursionSendScheduler: SendScheduler {
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
        var index = 0
        while index < sendPendingBuffer.count {
            sendPendingBuffer[index]()
            index += 1
        }
        sendPendingBuffer.removeAll()
        isSending = false
    }

    typealias SendPending = () -> Void
}
