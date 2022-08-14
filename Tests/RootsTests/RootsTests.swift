import Roots
import SwiftUI
import XCTest

class RootsTests: XCTestCase {
    final class Foobar: Saga<Count, Count.Action> {
        @MiddlewareBuilder override var run: Middleware<Count, Count.Action> {
            Put(.increment(100))
            Select { state in
                Put(.increment(state.count))
            }
        }
    }
}

@resultBuilder
public enum MiddlewareBuilder {
    static func buildBlock<State, Action>(_ middlewares: Middleware<State, Action>...) -> Middleware<State, Action> {
        CombineMiddleware(middlewares)
    }
}

public protocol SagaBuilder {
    associatedtype State
    associatedtype Action

    @MiddlewareBuilder var run: Middleware<State, Action> { get }
}

open class Saga<State, Action>: SagaBuilder {
    @MiddlewareBuilder open var run: Middleware<State, Action> {
        Never()
    }
}

public extension Saga {
    final class Never: Middleware<State, Action> {
        override public func respond(to _: Action, forwardingTo _: Dispatch<Action>) {
            fatalError()
        }
    }

    final class Put: Middleware<State, Action> {
        let action: Action

        public init(_ action: Action) {
            self.action = action
        }

        override public func respond(to action: Action, forwardingTo next: Dispatch<Action>) {
            next(action)
        }
    }

    final class Select: Middleware<State, Action> {
        init(@MiddlewareBuilder _: (State) -> Middleware<State, Action>) {}

        override public func respond(to _: Action, forwardingTo _: Dispatch<Action>) {}
    }
}
