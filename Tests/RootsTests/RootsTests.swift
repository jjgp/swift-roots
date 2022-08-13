import XCTest

class RootsTests: XCTestCase {
    func testRoots() {
        _ = rootsBuilder()
    }
}

public protocol Root {
    associatedtype Action
}

public struct Put<Action>: Root {
    let action: Action

    public init(_ action: Action) {
        self.action = action
    }

    public init(_: (Action) -> Action) {
        fatalError()
    }
}

public struct Take<Action>: Root {
    public init(_: Action) where Action: Equatable {}

    public init(_: (Action, Action) -> Bool) {}
}

public struct Roots<Action> {}

@resultBuilder
public enum RootsBuilder {
    static func buildBlock<Action, R: Root>(_: R) -> Roots<Action> where R.Action == Action {
        Roots()
    }

    static func buildBlock<Action, R0: Root, R1: Root>(_: R0, _: R1) -> Roots<Action> where R0.Action == Action, R1.Action == Action {
        Roots()
    }
}

@RootsBuilder func rootsBuilder() -> Roots<String> {
    Take("foobar")
    Put("foobar")
}
