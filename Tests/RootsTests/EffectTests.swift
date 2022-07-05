import Combine
@testable import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let effect = Effect<Count>(publisher: { _, actionPublisher in
            actionPublisher
                .filter {
                    if case .increment = $0 {
                        return true
                    } else {
                        return false
                    }
                }
                .map { _ in
                    .decrement(10)
                }
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, 0, 10, 0])
    }

    func testAsynchronousEffect() {
//        let expect = expectation(description: "The value is decremented")
        let effect = Effect<Count>(transform: { _, action in
            try? await Task.sleep(nanoseconds: 100)
            if case let .increment(value) = action {
//                expect.fulfill()
                return .decrement(value)
            }
            return nil
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:)
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        let values = spy.values.map(\.count)
//        wait(for: [expect], timeout: .infinity)
        XCTAssertEqual(values, [0, 10])
    }
}
