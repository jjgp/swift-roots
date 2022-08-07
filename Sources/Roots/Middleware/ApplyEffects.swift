import Combine

public func apply<State, Action>(effects _: Effect<State, Action>...) -> Middleware<State, Action> {
    fatalError()
//    apply(effects: effects)
}

// public func apply<State, Action>(effects: [Effect<State, Action>]) -> Middleware<State, Action> {
//    var cancellables = Set<AnyCancellable>()
//    let effect = combine(effects: effects)
//    let transitionPublisher = PassthroughSubject<Transition<State, Action>, Never>()
//    return .init { store in
//        effect.apply(transitionPublisher.eraseToAnyPublisher(), store.send(_:), &cancellables)

//        return { next in
//            { action in
//                next(action)
//            }
//        }
//    }
// }
