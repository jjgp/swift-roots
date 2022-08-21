import Roots
import RootsTest
import XCTest

class DependentEpicTests: XCTestCase {
    func testContextEffect() {
        // Given an context effect that increments the value to a value specified by the context
        let spy = EpicSpy(.incrementToContextValue().createEpic(Dependencies(value: 100)))

        // When an increment is less than the value
        spy.send(state: .init(count: 1), action: .increment(1))

        // Then another action is sent to increment to that value
        XCTAssertEqual(spy.values, [.increment(99)])
    }
}

private extension DependentEpicTests {
    struct Dependencies {
        let value: Int
    }
}

private extension Epic {
    static func incrementToContextValue() -> CountDependentEpic {
        .init { states, actions, context in
            states
                .filter { state in
                    state.count < context.value
                }
                .zip(actions)
                .compactMap { _, action in
                    if case let .increment(value) = action {
                        return .increment(context.value - value)
                    } else {
                        return nil
                    }
                }
        }
    }

    typealias CountDependentEpic = DependentEpic<Count, Count.Action, DependentEpicTests.Dependencies>
}
