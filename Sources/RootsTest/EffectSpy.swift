import Combine
import Roots

public class EffectSpy<State, Action>: Subscriber {
    private let actionSubject = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    public private(set) var finished = false
    private var subscription: Subscription!
    private let statePublisher = PassthroughSubject<State, Never>()
    private let actionPublisher = PassthroughSubject<Action, Never>()
    public private(set) var values: [Input] = []

    public init(_ effect: Effect<State, Action>) {
        actionSubject.subscribe(self)

        effect
            .createPublisher(statePublisher.eraseToAnyPublisher(), actionPublisher.eraseToAnyPublisher())
            .sink(receiveValue: actionSubject.send(_:))
            .store(in: &cancellables)
    }

    public convenience init<Context>(_ contextEffect: ContextEffect<State, Action, Context>, in context: Context) {
        self.init(contextEffect.createEffect(context))
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

    func receive(completion: Subscribers.Completion<Never>) {
        switch completion {
        case .finished:
            finished = true
        }
    }

    typealias Input = Action
    typealias Failure = Never
}

public extension EffectSpy {
    func send(state: State, action: Action) {
        statePublisher.send(state)
        actionPublisher.send(action)
    }
}
