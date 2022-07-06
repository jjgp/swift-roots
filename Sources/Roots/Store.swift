import Combine
import Foundation

public final class Store<S: State>: ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    let subject = PassthroughSubject<Action, Never>()
    @Published private(set) var state: S

    public init(initialState: S,
                reducer: @escaping Reducer<S>,
                effect: Effect<S>? = nil)
    {
        state = initialState
        combine(state, reducer: reducer, effect: effect)
    }

    init<Parent: State>(
        from keyPath: WritableKeyPath<Parent, S>,
        on parent: Store<Parent>,
        reducer: @escaping Reducer<S>,
        effect: Effect<S>? = nil
    ) {
        state = parent.state[keyPath: keyPath]
        combine(state, reducer: reducer, effect: effect) { [weak parent] nextState in
            parent?.state[keyPath: keyPath] = nextState
        }
    }
}

private extension Store {
    @inline(__always)
    func combine(
        _ state: S,
        reducer: @escaping Reducer<S>,
        effect: Effect<S>?,
        onUpdateState: ((S) -> Void)? = nil
    ) {
        let stateActionPair = subject
            .scan(state) { [weak self] previousState, action in
                var nextState = previousState
                nextState = reducer(&nextState, action)
                if previousState != nextState {
                    onUpdateState?(nextState)
                    self?.state = nextState
                }
                return nextState
            }
            .zip(subject)
            .share()

        effect?
            .effect(stateActionPair.eraseToAnyPublisher(), subject.send(_:))
            .store(in: &cancellables)

        // TODO: need to find a cleaner way to start signal without effects!
        stateActionPair.sink(receiveValue: { $0 }).store(in: &cancellables)
    }
}

public extension Store {
    func store<T: State>(
        from keyPath: WritableKeyPath<S, T>,
        reducer: @escaping Reducer<T>
    ) -> Store<T> {
        Store<T>(from: keyPath, on: self, reducer: reducer)
    }
}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
