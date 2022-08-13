import Foundation

public final class DispatchPrecondition<State, Action>: Middleware<State, Action> {
    private let predicate: DispatchPredicate

    public init(predicate: DispatchPredicate) {
        self.predicate = predicate
    }

    override public func respond(to action: Action, forwardingTo next: Dispatch<Action>) {
        dispatchPrecondition(condition: predicate)
        next(action)
    }
}
