import Roots
import RootsTest
import XCTest

class CombineEffectTests: XCTestCase {
    /*
     Both effects in either test should be applied to the store after combining them into a single effect with
     combine(effect:). Note that the effects are downstream of the transition publisher and Combine makes no guarantee
     in regards to the order of delivery. This means that the order the effects are run is indeterminate.
     */

    func testCombineEffects() {
        // Given an effect that increments the value to 100 and another that decrements the a count of 100 to 0
        let spy = EffectSpy<Count, Count.Action>(combine(effects:
            .subject { state, action, send in
                if state.count < 100, case let .increment(value) = action {
                    send(.increment(100 - value))
                }
            },
            .subject { state, _, send in
                if state.count == 100 {
                    send(.decrement(100))
                }
            }))

        // When sending any value...
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        spy.send(state: .init(count: 100), action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }

    func testCombineContextWithEffects() {
        // Given an effect that increments the value to a value specified by the context and another that decrements to 0
        struct Context {
            let value = 100
        }
        let spy = EffectSpy<Count, Count.Action>(combine(context: Context(), with:
            .subject { state, action, send, context in
                if state.count < context.value, case let .increment(value) = action {
                    send(.increment(context.value - value))
                }
            },
            .subject { state, _, send, context in
                if state.count == context.value {
                    send(.decrement(context.value))
                }
            }))

        // When sending any value...
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        spy.send(state: .init(count: 100), action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }
}
