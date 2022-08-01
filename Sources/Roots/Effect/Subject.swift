import Combine

public extension Effect {
    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.init { transitionPublisher in
            let subject = PassthroughSubject<Action, Never>()
            let cancellable = transitionPublisher.sink { transition in
                effect(transition.state, transition.action, subject.send)
            }
            return [Artifact](cancellables: cancellable, publishers: subject)
        }
    }

    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        .subject { state, action, send in
            Task {
                await effect(state, action, send)
            }
        }
    }

    typealias SubjectEffect = (State, Action, @escaping Send) -> Void
    typealias AsyncSubjectEffect = (State, Action, @escaping Send) async -> Void
}

public extension ContextEffect {
    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.init { context in
            .subject { state, action, send in
                effect(state, action, send, context)
            }
        }
    }

    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        self.init { context in
            .subject { state, action, send in
                Task {
                    await effect(state, action, send, context)
                }
            }
        }
    }

    typealias SubjectEffect = (State, Action, @escaping Send, Context) -> Void
    typealias AsyncSubjectEffect = (State, Action, @escaping Send, Context) async -> Void
}
