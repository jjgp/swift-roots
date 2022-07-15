import Roots
import XCTest

class PublisherEffectTests: XCTestCase {
    func testPublisherEffect() {
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
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testPublisherOfEnvironmentEffect() {
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
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }
}
