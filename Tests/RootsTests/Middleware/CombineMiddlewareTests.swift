import Roots
import RootsTest
import XCTest

class CombineMiddlewareTests: XCTestCase {
    func testCombinationOfMultipleMiddleware() {
        // Given a store with multiple middleware
        let countStore = Store(
            initialState: Counts(),
            reducer: Counts.reducer(state:action:),
            middleware: CombineMiddleware(
                ApplyEffects(.settIncrementAndDecrementValuesToOne()),
                RunThunk()
            )
        )
        let countSpy = PublisherSpy(countStore)

        // When actions are sent that trigger either middleware
        countStore.send(creator: \.addToCount, passing: \.first, 100)
        countStore.send(creator: \.addToCount, passing: \.first, -100)
        countStore.send(Thunk<Counts, Action> { dispatch, getState in
            if getState().first.count == 2 {
                dispatch(Counts.Addition(keyPath: \.first, value: 100))
            }
        })

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
                        return Counts.Addition(keyPath: action.keyPath, value: 1)
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
