import Roots

open class SendSchedulerSpy: SendScheduler {
    open var sendPendingBuffer: [SendPending] = []

    public init() {}

    open func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>) {
        sendPendingBuffer.append {
            send(action)
            return action
        }
    }

    open func sendNext<Action>() -> Action? {
        sendPendingBuffer.removeFirst()() as? Action
    }

    public typealias SendPending = () -> Any
}
