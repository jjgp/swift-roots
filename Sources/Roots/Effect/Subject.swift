import Combine

public extension Effect {
    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        .subject { state, action, send in
            Task {
                await effect(state, action, send)
            }
        }
    }

    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.init { transitionPublisher in
            let subject = PassthroughSubject<Action, Never>()
            let cancellable = transitionPublisher.sink { transition in
                effect(transition.state, transition.action, subject.send)
            }
            return [Cause](cancellables: cancellable, publishers: subject)
        }
    }

    typealias AsyncSubjectEffect = (State, Action, @escaping Dispatch<Action>) async -> Void
    typealias SubjectEffect = (State, Action, @escaping Dispatch<Action>) -> Void
}

public extension ContextEffect {
    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        .subject { state, action, send, context in
            Task {
                await effect(state, action, send, context)
            }
        }
    }

    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.init { context in
            .subject { state, action, send in
                effect(state, action, send, context)
            }
        }
    }

    typealias AsyncSubjectEffect = (State, Action, @escaping Dispatch<Action>, Context) async -> Void
    typealias SubjectEffect = (State, Action, @escaping Dispatch<Action>, Context) -> Void
}
