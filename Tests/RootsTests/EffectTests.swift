import Combine
@testable import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let effect = Effect<Count>(transform: { _, action in
            if case let .increment(value) = action {
                return .decrement(value)
            } else {
                return nil
            }
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )

        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, 0, 20, 0, 40, 0])
    }

    func testAsynchronousEffect() {
        let expect = expectation(description: "The value is decremented")
        let effect = Effect<Count>(transform: { _, action in
            // TODO: need to find way to reschedule onto the dispatching queue/thread
            // Currently the decrement has no effect because the Future/Task will go to another queue
            // Setting a breakpoint after store.send(:) will pause the main queue and allow decrement to take effect
            try? await Task.sleep(nanoseconds: 100)
            if case .increment = action {
                return .decrement(100)
            } else if case .decrement = action {
                expect.fulfill()
            }
            return nil
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        wait(for: [expect], timeout: .infinity)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testPublisherEffect() {
        let effect = Effect<Count>(publisher: { stateActionPair in
            stateActionPair
                .filter { _, action in
                    if case .increment = action {
                        return true
                    } else {
                        return false
                    }
                }
                .map { _ in .decrement(100) }
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }
}
