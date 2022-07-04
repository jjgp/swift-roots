import Combine

public protocol ActionSender {
    associatedtype S: State

    func send(_ action: Action)

    // TODO: support subscribe without combine

    typealias Action = S.Action
}

protocol ActionSubject: ActionSender {
    var subject: PassthroughSubject<Action, Never> { get }
}
