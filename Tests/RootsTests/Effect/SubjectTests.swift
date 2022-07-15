import Roots
import XCTest

class SubjectEffectTests: XCTestCase {
    func testSubjectEffect() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .subject { _, action, send in
                if case let .increment(value) = action {
                    send(.decrement(value))
                }
            }
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, 0, 20, 0, 40, 0])
    }

    func testSubjectOfEnvironmentEffect() {
        struct Environment {
            let multiplier = 2
        }
        let environment = Environment()
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .subject(of: environment) { _, action, send, environment in
                if case let .increment(value) = action {
                    send(.decrement(environment.multiplier * value))
                }
            }
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 10, -30, 10, -70])
    }

    func testAsyncSubjectEffect() {
        let expect = expectation(description: "The value is decremented")
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .subject { _, action, send in
                if case .increment = action {
                    await MainActor.run {
                        send(.decrement(100))
                    }
                } else if case .decrement = action {
                    expect.fulfill()
                }
            }
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testAsyncSubjectEffectOfEnvironment() {
        struct Environment {
            let multiplier = 2
        }
        let environment = Environment()
        let expect = expectation(description: "The value is decremented")
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .subject(of: environment) { _, action, send, environment in
                if case .increment = action {
                    await MainActor.run {
                        send(.decrement(environment.multiplier * 100))
                    }
                } else if case .decrement = action {
                    expect.fulfill()
                }
            }
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -190])
    }
}
