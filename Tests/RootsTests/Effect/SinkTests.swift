import Roots
import XCTest

class SinkEffectTests: XCTestCase {
    func testSinkEffect() {
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
        store.send(.increment(10))
        XCTAssertEqual(value, 10)
    }

    func testSinkOfEnvironmentEffect() {
        struct Environment {
            let multiplier = 2
        }
        let environment = Environment()
        var value = 0
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .sink(of: environment) { transitionPublisher, environment in
                transitionPublisher
                    .compactMap {
                        if case let .increment(value) = $0.action {
                            return environment.multiplier * value
                        } else {
                            return nil
                        }
                    }
                    .sink {
                        value = $0
                    }
            }
        )
        store.send(.increment(10))
        XCTAssertEqual(value, 20)
    }
}
