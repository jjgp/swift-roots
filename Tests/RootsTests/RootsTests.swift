import Roots
import XCTest

class RootsTests: XCTestCase {
    func testRoots() {
//        _ = rootsBuilder()
    }
}

open class Root<Action> {
    open func respond(to _: Action, chainingTo _: Dispatch<Action>) {}
}

open class StatefulRoot<State, Action>: Root<Action> {}

@resultBuilder
public enum RootsBuilder {
    static func buildBlock<Action>(_ roots: Root<Action>) -> Root<Action> {
        roots
    }
}

public final class Put<Action>: Root<Action> {
    let action: Action

    public init(_ action: Action) {
        self.action = action
    }

    override public func respond(to action: Action, chainingTo next: Dispatch<Action>) {
        next(action)
    }
}

public final class Select<State, Action>: StatefulRoot<State, Action> {
    init(@RootsBuilder _: (State) -> Root<Action>) {}
}

@RootsBuilder func rootsBuilder() -> Root<Count.Action> {
    Select { (state: Count) in
        let action: Count.Action = .decrement(state.count)

        Put(action)
    }
}
