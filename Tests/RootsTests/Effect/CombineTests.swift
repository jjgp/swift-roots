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
        let spy = EffectSpy(combine(effects: .incrementTo100(), .decrement100To0()))

        // When sending any value...
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        spy.send(state: .init(count: 100), action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }

    func testCombineContextWithEffects() {
        // Given a context effect that increments the value to a value specified by the context and another that decrements to 0
        let spy = EffectSpy(
            combine(context: Context(value: 100), with: .incrementToContextValue(), .decrementContextValueTo0())
        )

        // When sending any value...
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        spy.send(state: .init(count: 100), action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }
}

extension CombineEffectTests {
    struct Context {
        let value: Int
    }
}

extension ContextEffect where S == Count, Action == Count.Action, Context == CombineEffectTests.Context {
    static func incrementToContextValue() -> Self {
        .subject { state, action, send, context in
            if state.count < context.value, case let .increment(value) = action {
                send(.increment(context.value - value))
            }
        }
    }

    static func decrementContextValueTo0() -> Self {
        .subject { state, _, send, context in
            if state.count == context.value {
                send(.decrement(context.value))
            }
        }
    }
}

extension Effect where S == Count, Action == Count.Action {
    static func incrementTo100() -> Self {
        .subject { state, action, send in
            if state.count < 100, case let .increment(value) = action {
                send(.increment(100 - value))
            }
        }
    }

    static func decrement100To0() -> Self {
        .subject { state, _, send in
            if state.count == 100 {
                send(.decrement(100))
            }
        }
    }
}
