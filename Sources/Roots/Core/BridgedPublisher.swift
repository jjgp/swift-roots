import Combine

public struct BridgedPublisher<Output>: Combine.Publisher {
    private let subscribeReceiveValue: (@escaping (Output) -> Void) -> Cancellable

    init<P: Publisher>(_ publisher: P) where P.Output == Output {
        subscribeReceiveValue = publisher.subscribe(receiveValue:)
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = Subscription<S>()
        subscription.subscriber = subscriber
        subscription.cancellable = subscribeReceiveValue { [weak subscription] value in
            subscription?.receive(value)
        }

        subscriber.receive(subscription: subscription)
    }

    public typealias Failure = Never
}

private extension BridgedPublisher {
    class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output {
        var cancellable: Cancellable?
        var subscriber: S?

        func receive(_ input: Output) {
            _ = subscriber?.receive(input)
        }

        func request(_: Subscribers.Demand) {
            // TODO: handle demand
        }

        func cancel() {
            subscriber = nil
            cancellable?.cancel()
            cancellable = nil
        }
    }
}

public extension Publisher {
    var asBridged: BridgedPublisher<Output> {
        .init(self)
    }
}
