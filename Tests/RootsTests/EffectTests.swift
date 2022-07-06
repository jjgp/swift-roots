import Combine
@testable import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let effect = Effect<Count>(sender: { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(value))
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
        let effect = Effect<Count>(sender: { _, action, send in
            try? await Task.sleep(nanoseconds: 100)
            if case .increment = action {
                await MainActor.run {
                    send(.decrement(100))
                }
            } else if case .decrement = action {
                expect.fulfill()
            }
        })
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        wait(for: [expect], timeout: .infinity)
        let values = spy.values.map(\.count)
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
