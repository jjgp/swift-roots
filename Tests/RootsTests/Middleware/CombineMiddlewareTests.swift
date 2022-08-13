import Roots
import RootsTest
import XCTest

class CombineMiddlewareTests: XCTestCase {
    func testCombinationOfMultipleMiddleware() {
        let countStore = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            middleware: CombineMiddleware(
                ApplyEffects(.settIncrementAndDecrementValuesToOne()),
                RunThunk()
            )
        )
        let countSpy = PublisherSpy(countStore)

        countStore.send(.increment(100))
        countStore.send(.decrement(100))

        let values = countSpy.values.map(\.count)
        XCTAssertEqual(values, [0, 100, 101, 1, 0])
    }
}

private extension Effect where State == Count, Action == Count.Action {
    static func settIncrementAndDecrementValuesToOne() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                if case let .increment(value) = action, value != 1 {
                    return .increment(1)
                } else if case let .decrement(value) = action, value != 1 {
                    return .decrement(1)
                } else {
                    return nil
                }
            }
        }
    }
}
