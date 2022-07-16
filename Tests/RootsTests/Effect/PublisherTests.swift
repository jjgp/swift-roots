import Roots
import XCTest

class PublisherEffectTests: XCTestCase {
    func testPublisherEffect() {
        // Given a store with a publisher effect that decrements by 100 and matches increments of 10
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .publisher { transitionPublisher in
                transitionPublisher
                    .filter { $0.action == .increment(10) }
                    .map { _ in .decrement(100) }
            }
        )
        let spy = PublisherSpy(store)

        // When an action increments by 10
        store.send(.increment(10))

        // Then the emitted state should show the increment/decrement
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testPublisherOfEnvironmentEffect() {
        // Given a store with a publisher effect that decrements by and matches increments of the environment values
        struct Environment {
            let incrementValue = 10
            let decrementValue = 100
        }
        let environment = Environment()
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .publisher(of: environment) { transitionPublisher, environment in
                transitionPublisher
                    .filter { $0.action == .increment(environment.incrementValue) }
                    .map { _ in .decrement(environment.decrementValue) }
            }
        )
        let spy = PublisherSpy(store)

        // When an action increments by the matched environment value
        store.send(.increment(10))

        // Then the emitted state should show the increment/decrement
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }
}
