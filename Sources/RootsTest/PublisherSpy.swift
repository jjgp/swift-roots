import Combine

public class PublisherSpy<Input, Failure: Error>: Subscriber {
    public private(set) var failure: Failure?
    public private(set) var finished = false
    public private(set) var values: [Input] = []
    private var subscription: Subscription!

    public init<P: Publisher>(_ publisher: P) where P.Output == Input, P.Failure == Failure {
        publisher.subscribe(self)
    }
}

public extension PublisherSpy {
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        values.append(input)
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        switch completion {
        case .finished:
            finished = true
        case let .failure(error):
            failure = error
        }
    }
}
