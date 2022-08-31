import Combine

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
        var subscriber: S?

        func receive(_ input: Output) {
            lock {
                guard demand > 0, let subscriber = subscriber else {
                    return
                }

                demand -= 1
                demand += subscriber.receive(input)
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
    var asBridged: BridgedPublisher<Output> {
        .init(self)
    }
}
