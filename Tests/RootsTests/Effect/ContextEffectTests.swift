import Roots
import RootsTest
import XCTest

class ContextEffectTests: XCTestCase {
    func testContextEffect() {
        // Given an context effect that increments the value to a value specified by the context
        struct Context {
            let value = 100
        }
        let contextEffect = ContextEffect<Count, Count.Action, Context> { context in
            Effect { transitionPublisher in
                let publisher = transitionPublisher.compactMap { transition -> Count.Action? in
                    if transition.state.count < context.value, case let .increment(value) = transition.action {
                        return .increment(context.value - value)
                    } else {
                        return nil
                    }
                }

                return .init(publisher)
            }
        }

        let spy = EffectSpy(contextEffect, in: .init())

        // When an increment is less than the value
        spy.send(state: .init(count: 1), action: .increment(1))

        // Then another action is sent to increment to that value
        XCTAssertEqual(spy.values, [.increment(99)])
    }
}
