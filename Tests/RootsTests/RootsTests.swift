import XCTest

class RootsTests: XCTestCase {
    func testRoots() {
        _ = rootsBuilder()
    }
}

public protocol Root {}
public struct Call: Root {}
public struct Put: Root {}
public struct Take: Root {}

@resultBuilder
public enum RootsBuilder {
    static func buildBlock(_ roots: Root...) -> Root {
        print(roots)
        return Take()
    }
}

@RootsBuilder func rootsBuilder() -> Root {
    Take()
    Put()
    Call()
}
