import Roots
import RootsTest
import XCTest

class SinkEffectTests: XCTestCase {
    func testSinkEffect() {
        // Given a sink effect that observes the incremented value
        var value = 0
        let spy = EffectSpy<Count, Count.Action>(.sink { transitionPublisher in
            transitionPublisher
                .compactMap {
                    if case let .increment(value) = $0.action {
                        return value
                    } else {
                        return nil
                    }
                }
                .sink {
                    value = $0
                }
        })

        // When sending an increment by a value
        spy.send(state: .init(count: 10), action: .increment(10))

        // Then the observed value should be equal
        XCTAssertEqual(value, 10)
    }
}
