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
        let spy = EffectSpy(.combine(effects: .incrementTo100(), .decrement100To0()))

        // When sending any value...
        var state = Count(count: 1)
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        state.count += 99
        spy.send(state: state, action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }

    func testCombineContextWithEffects() {
        // Given a context effect that increments the value to a value specified by the context and another that decrements to 0
        let spy = EffectSpy(
            .combine(context: Context(value: 100), and: .incrementToContextValue(), .decrementContextValueTo0())
        )

        // When sending any value...
        spy.send(state: .init(count: 1), action: .increment(1))
        // ...and simulating the increment to 100
        spy.send(state: .init(count: 100), action: .increment(99))

        // Then it's expected to see the values incremented to 100 and subsequently decremented to 0
        XCTAssertEqual(spy.values, [.increment(99), .decrement(100)])
    }
}

private extension XCTestCase {
    struct Context {
        let value: Int
    }
}

private extension ContextEffect where State == Count, Action == Count.Action, Context == XCTestCase.Context {
    static func incrementToContextValue() -> Self {
        ContextEffect { states, actions, context in
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

    static func decrementContextValueTo0() -> Self {
        ContextEffect { states, _, context in
            states
                .filter { state in
                    state.count == context.value
                }
                .map { _ in
                    .decrement(context.value)
                }
        }
    }
}

private extension Effect where State == Count, Action == Count.Action {
    static func incrementTo100() -> Self {
        Effect { states, actions in
            states
                .filter { state in
                    state.count < 100
                }
                .zip(actions)
                .compactMap { _, action in
                    if case let .increment(value) = action {
                        return .increment(100 - value)
                    } else {
                        return nil
                    }
                }
        }
    }

    static func decrement100To0() -> Self {
        Effect { states, _ in
            states
                .filter { state in
                    state.count == 100
                }
                .map { _ in
                    .decrement(100)
                }
        }
    }
}
