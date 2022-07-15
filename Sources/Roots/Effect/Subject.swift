import class Combine.PassthroughSubject

public extension Effect {
    static func subject(_ effect: @escaping SubjectEffect) -> Self {
        self.effect { transitionPublisher in
            let subject = PassthroughSubject<A, Never>()
            let cancellable = transitionPublisher.sink { transition in
                effect(transition.state, transition.action, subject.send)
            }
            return [cancellable.toEffectArtifact(), subject.toEffectArtifact()]
        }
    }

    static func subject<Environment>(of environment: Environment, effect: @escaping SubjectEffectOfEnvironment<Environment>) -> Self {
        self.subject { state, action, send in
            effect(state, action, send, environment)
        }
    }

    static func subject(_ effect: @escaping AsyncSubjectEffect) -> Self {
        self.subject { state, action, send in
            Task {
                await effect(state, action, send)
            }
        }
    }

    static func subject<Environment>(of environment: Environment, effect: @escaping AsyncSubjectEffectOfEnvironment<Environment>) -> Self {
        self.subject { state, action, send in
            await effect(state, action, send, environment)
        }
    }

    typealias SubjectEffect = (S, A, @escaping Send) -> Void
    typealias SubjectEffectOfEnvironment<Environment> = (S, A, @escaping Send, Environment) -> Void
    typealias AsyncSubjectEffect = (S, A, @escaping Send) async -> Void
    typealias AsyncSubjectEffectOfEnvironment<Environment> = (S, A, @escaping Send, Environment) async -> Void
}
