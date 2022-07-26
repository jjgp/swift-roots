import Roots
import RootsTest
import XCTest

class PublisherEffectTests: XCTestCase {
    func testPublisherEffect() {
        // Given a publisher effect that decrements by 100 and matches increments of 10
        let spy = EffectSpy(.mapIncrementsToDecrementBy100())

        // When an action increments by 10
        spy.send(state: .init(count: 10), action: .increment(10))

        // Then the emitted action should decrement
        XCTAssertEqual(spy.values, [.decrement(100)])
    }
}

private extension Effect where S == Count, Action == Count.Action {
    static func mapIncrementsToDecrementBy100() -> Self {
        .publisher { transitionPublisher in
            transitionPublisher
                .filter { $0.action == .increment(10) }
                .map { _ in .decrement(100) }
        }
    }
}
