import Combine
import Roots

public class EffectSpy<S: State, Action>: Subscriber {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    public private(set) var finished = false
    public private(set) var values: [Input] = []
    private var subscription: Subscription!
    private let transitionSubject = PassthroughSubject<Transition<S, Action>, Never>()

    public init(_ effect: Effect<S, Action>) {
        effect.apply(
            transitionSubject.eraseToAnyPublisher(),
            actionSubject.send(_:),
            &cancellables
        )
        actionSubject.subscribe(self)
    }
}

public extension EffectSpy {
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

    typealias Input = Action
    typealias Failure = Never
}

public extension EffectSpy {
    func send(state: S, action: Action) {
        transitionSubject.send(.init(state: state, action: action))
    }
}
