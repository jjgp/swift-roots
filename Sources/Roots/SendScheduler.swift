public protocol SendScheduler {
    func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>)
}

public final class OneAtATimeSendScheduler: SendScheduler {
    private var isSending = false
    private var sendBuffer: [SendPending] = []

    public init() {}

    public func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>) {
        guard !isSending else {
            sendBuffer.append {
                send(action)
            }
            return
        }

        isSending = true
        send(action)
        while !sendBuffer.isEmpty {
            sendBuffer.swapAt(0, sendBuffer.count - 1)
            sendBuffer.removeLast()()
        }
        isSending = false
    }

    typealias SendPending = () -> Void
}
