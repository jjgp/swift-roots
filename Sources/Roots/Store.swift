import Combine
import Foundation

public final class Store<S: State>: ActionSubject {
    private(set) var cancellables: Set<AnyCancellable> = []
    @Published private(set) var state: S
    let subject = PassthroughSubject<Action, Never>()

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
        // TODO: cache the children store and return it for subsequent calls. Would be ideal if
        // it was weakly referenced...
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

        (effect ?? .noEffect)
            .effect(stateActionPair.eraseToAnyPublisher()) { [weak self] action in
                self?.subject.send(action)
            }
            .store(in: &cancellables)
    }
}

public extension Store {
    func store<T: State>(
        from keyPath: WritableKeyPath<S, T>,
        reducer: @escaping Reducer<T>,
        effect: Effect<T>? = nil
    ) -> Store<T> {
        Store<T>(from: keyPath, on: self, reducer: reducer, effect: effect)
    }
}

public extension Store {
    func send(_ action: Action) {
        subject.send(action)
    }
}
