import Roots
import RootsTest
import XCTest

class ApplyEffectsTests: XCTestCase {
    func testApplicationOfMultipleEffects() {
        let countStore = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            middleware: ApplyEffects(
                .decrementByPreviousOdd(),
                .incrementByNextEven()
            )
        )
        let countSpy = PublisherSpy(countStore)

        countStore.send(.increment(1))
        countStore.send(.decrement(2))

        let values = countSpy.values.map(\.count)
        XCTAssertEqual(values, [0, 1, 3, 1, 0])
    }
}

private extension Effect where State == Count, Action == Count.Action {
    static func decrementByPreviousOdd() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                if case let .decrement(value) = action, value % 2 == 0 {
                    return .decrement(value - 1)
                } else {
                    return nil
                }
            }
        }
    }

    static func incrementByNextEven() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                if case let .increment(value) = action, value % 2 == 1 {
                    return .increment(value + 1)
                } else {
                    return nil
                }
            }
        }
    }
}
