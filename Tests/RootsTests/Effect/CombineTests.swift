import Roots
import XCTest

class CombineEffectTests: XCTestCase {
    func testCombineEffects() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: combine(effects:
                .subject { state, action, send in
                    if state.count < 100, case let .increment(value) = action {
                        send(.increment(100 - value))
                    }
                },
                .subject { state, _, send in
                    if state.count == 100 {
                        send(.decrement(100))
                    }
                })
        )
        let spy = PublisherSpy(store)
        store.send(.increment(1))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 1, 100, 0])
    }
}
