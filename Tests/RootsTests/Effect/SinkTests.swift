import Roots
import XCTest

class SinkEffectTests: XCTestCase {
    func testSinkEffect() {
        // Given a store with a sink effect that observes the incremented value
        var value = 0
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .sink { transitionPublisher in
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
            }
        )

        // When sending an increment by a value
        store.send(.increment(10))

        // Then the observed value should be equal
        XCTAssertEqual(value, 10)
    }
}
