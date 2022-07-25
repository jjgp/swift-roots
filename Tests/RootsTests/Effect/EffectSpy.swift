import Combine
@testable import Roots

class EffectSpy<S: State, Action>: Subscriber {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    private(set) var finished = false
    private(set) var values: [Input] = []
    private(set) var subscription: Subscription!
    private let transitionSubject = PassthroughSubject<Transition<S, Action>, Never>()

    init(_ effect: Effect<S, Action>) {
        effect.apply(
            transitionSubject.eraseToAnyPublisher(),
            actionSubject.send(_:),
            &cancellables
        )
        actionSubject.subscribe(self)
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        values.append(input)
        return .unlimited
    }

    func receive(completion _: Subscribers.Completion<Never>) {
        finished = false
    }

    func send(state: S, action: Action) {
        transitionSubject.send(.init(state: state, action: action))
    }

    typealias Input = Action
    typealias Failure = Never
}
