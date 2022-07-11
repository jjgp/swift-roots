import Combine

public protocol ActionSender {
    associatedtype S: State
    associatedtype A: Action

    func send(_ action: A)
}

protocol ActionSubject: ActionSender {
    var subject: PassthroughSubject<A, Never> { get }
}
