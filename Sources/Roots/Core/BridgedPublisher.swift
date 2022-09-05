import Combine
import Foundation

public struct BridgedPublisher<Output>: Combine.Publisher {
    private let subscribeReceiveValue: (@escaping (Output) -> Void) -> Cancellable

    init<P: Publisher>(_ publisher: P) where P.Output == Output {
        subscribeReceiveValue = publisher.subscribe(receiveValue:)
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = Subscription<S>()
        subscription.subscriber = subscriber
        subscriber.receive(subscription: subscription)

        subscription.cancellable = subscribeReceiveValue { [weak subscription] value in
            subscription?.receive(value)
        }
    }

    public typealias Failure = Never
}

private extension BridgedPublisher {
    class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output {
        var cancellable: Cancellable?
        private var demand: Subscribers.Demand = .none
        private let lock: UnfairLock = .init()
        private let recursiveLock = NSRecursiveLock()
        var subscriber: S?

        func receive(_ input: Output) {
            lock.lock()
            guard demand > 0, let subscriber = subscriber else {
                lock.unlock()
                return
            }
            demand -= 1
            lock.unlock()

            recursiveLock.lock()
            let demand = subscriber.receive(input)
            recursiveLock.unlock()

            if demand > 0 {
                lock {
                    self.demand += demand
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            lock {
                guard subscriber != nil else {
                    return
                }

                self.demand += demand
            }
        }

        func cancel() {
            lock {
                subscriber = nil
            }
        }
    }
}

public extension Publisher {
    func bridged() -> BridgedPublisher<Output> {
        .init(self)
    }
}
