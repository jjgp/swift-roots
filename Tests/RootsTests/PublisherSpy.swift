import Combine

class PublisherSpy<Input, Failure: Error>: Subscriber {
    private(set) var failure: Failure?
    private(set) var finished = false
    private(set) var values: [Input] = []
    private(set) var subscription: Subscription!

    init<P: Publisher>(_ publisher: P) where P.Output == Input, P.Failure == Failure {
        publisher.subscribe(self)
    }

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
            finished = false
        case let .failure(error):
            failure = error
        }
    }
}
