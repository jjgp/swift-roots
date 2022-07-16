import Roots
import XCTest

class CombineEffectTests: XCTestCase {
    func testCombineEffects() {
        /*
         Both effects should be applied to the store after combining them into a single effect with
         combine(effect:). Note that the effects are downstream of the transition publisher and
         Combine makes no guarantee in regards to the order of delivery. This means that the order
         the effects are run is indeterminate.
         */

        /*
         Given a store with an effect that increments the value to 100 and another that decrements
         the a count of 100 to 0
         */
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

        // When sending any value
        store.send(.increment(1))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 1, 100, 0])
    }
}
