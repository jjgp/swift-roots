import Roots
import RootsTest
import XCTest

class CombineMiddlewareTests: XCTestCase {
    func testCombinationOfMultipleMiddleware() {
        // Given a store with multiple middleware
        let countsStore = Store(
            initialState: Counts(),
            reducer: Counts.reducer(state:action:),
            middleware: ApplyEffects(.settIncrementAndDecrementValuesToOne())
        )
        let countSpy = PublisherSpy(countsStore)

        // When actions are sent that trigger either middleware
        countsStore.send(Counts.Addition(to: \.first, by: 100))
        countsStore.send(Counts.Addition(to: \.first, by: -100))

        countsStore.run { dispatch, getState in
            if getState().first.count == 2 {
                dispatch(Counts.Addition(to: \.first, by: 100))
            }
        }

        // Then the state should be updated according to those middleware
        let values = countSpy.values.map(\.first.count)
        XCTAssertEqual(values, [0, 100, 101, 1, 2, 102, 103])
    }
}

private extension Effect where State == Counts, Action == Roots.Action {
    static func settIncrementAndDecrementValuesToOne() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                switch action {
                case let action as Counts.Addition:
                    if action.value != 1 {
                        return Counts.Addition(to: action.keyPath, by: 1)
                    } else {
                        return nil
                    }
                default:
                    return nil
                }
            }
        }
    }
}
