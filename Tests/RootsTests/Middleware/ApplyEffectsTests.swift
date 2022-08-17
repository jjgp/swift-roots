import Roots
import RootsTest
import XCTest

class ApplyEpicsTests: XCTestCase {
    func testApplicationOfMultipleEffects() {
        // Given a store with multiple effects
        let countStore = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            middleware: ApplyEpics(
                .decrementByPreviousOdd(),
                .incrementByNextEven()
            )
        )
        let countSpy = PublisherSpy(countStore)

        // When actions are sent that trigger either effect
        countStore.send(.increment(1))
        countStore.send(.decrement(2))

        // Then the state should be updated according to those effects
        let values = countSpy.values.map(\.count)
        XCTAssertEqual(values, [0, 1, 3, 1, 0])
    }
}

private extension Epic {
    static func decrementByPreviousOdd() -> CountEpic {
        .init { _, actions in
            actions.compactMap { action in
                if case let .decrement(value) = action, value % 2 == 0 {
                    return .decrement(value - 1)
                } else {
                    return nil
                }
            }
        }
    }

    static func incrementByNextEven() -> CountEpic {
        .init { _, actions in
            actions.compactMap { action in
                if case let .increment(value) = action, value % 2 == 1 {
                    return .increment(value + 1)
                } else {
                    return nil
                }
            }
        }
    }

    typealias CountEpic = Epic<Count, Count.Action>
}
