import Combine

public final class Store<S: State>: StatePublisher, ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    private(set) var subject: PassthroughSubject<Action, Never>
    @Published private(set) var state: S
    var statePublished: Published<S> { _state }
    var statePublisher: Published<S>.Publisher { $state }

    public init(initialState: S) {
        state = initialState
        subject = PassthroughSubject<Action, Never>()
        subject
            // TODO: middleware and/or effects
            .scan(initialState) { state, action in
                var state = state
                return S.reducer(state: &state, action: action)
            }
            .removeDuplicates()
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

public extension Store {}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
