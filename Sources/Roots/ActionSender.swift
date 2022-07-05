import Combine

public protocol ActionSender {
    associatedtype S: State

    func send(_ action: Action)

    typealias Action = S.Action
}

protocol ActionSubject: ActionSender {
    var subject: PassthroughSubject<Action, Never> { get }
}
