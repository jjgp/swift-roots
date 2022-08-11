import Roots
import XCTest

open class SendSchedulerSpy: SendScheduler {
    open var sendPendingBuffer: [SendPending] = []
    open var sendHistory: [Any] = []

    public init() {}

    open func schedule<Action>(action: Action, sendingTo send: @escaping Dispatch<Action>) {
        sendPendingBuffer.append {
            send(action)
            return action
        }
    }

    open func sendHistory<Action>(at index: Int) -> Action? {
        sendHistory[index] as? Action
    }

    open func sendHistory<Action>(between range: ClosedRange<Int>) -> Action? {
        for other in sendHistory[range] {
            if let other = other as? Action {
                return other
            }
        }

        return nil
    }

    open func sendNext() {
        sendHistory.append(sendPendingBuffer.removeFirst()())
    }

    public typealias SendPending = () -> Any
}
