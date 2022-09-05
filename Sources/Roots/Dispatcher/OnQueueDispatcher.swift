import Foundation

public struct OnQueueDispatcher: Dispatcher {
    private let key = DispatchSpecificKey<UInt8>()
    private let queue: DispatchQueue
    private let value: UInt8 = 0

    public init(_ queue: DispatchQueue = .main) {
        self.queue = queue
        queue.setSpecific(key: key, value: value)
    }
}

public extension OnQueueDispatcher {
    func receive(action: Action, transmitTo dispatch: @escaping Dispatch) {
        if DispatchQueue.getSpecific(key: key) == value {
            dispatch(action)
        } else {
            queue.async {
                dispatch(action)
            }
        }
    }
}
