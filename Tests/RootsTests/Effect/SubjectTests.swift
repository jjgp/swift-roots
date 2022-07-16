import Roots
import XCTest

class SubjectEffectTests: XCTestCase {
    func testSubjectEffect() {
        // Given a store with a subject effect that decrements any incremented value
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

        // When sending any increments
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        // This action should be unaffected
        store.send(.decrement(40))

        // Then those increments should be decremented back to 0
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, 0, 20, 0, 40, 0, -40])
    }

    func testSubjectOfEnvironmentEffect() {
        // Given a store with a subject effect that decrements any incremented value by an environment specified multiple
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

        // When sending any increments
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        // This action should be unaffected
        store.send(.decrement(40))

        // Then those increments should be decremented by the multiplied amount
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 10, -30, 10, -70, -110])
    }

    func testAsyncSubjectEffect() {
        // Given a store with a async subject effect that decrements any increment by 100
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

        // When sending any increment
        store.send(.increment(10))

        // Then the increment should be decremented by 100
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testAsyncSubjectEffectOfEnvironment() {
        // Given a store with a async subject effect that decrements any increment by and environment specified value
        struct Environment {
            let decrementValue = 100
        }
        let environment = Environment()
        let expect = expectation(description: "The value is decremented")
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .subject(of: environment) { _, action, send, environment in
                if case .increment = action {
                    await MainActor.run {
                        send(.decrement(environment.decrementValue))
                    }
                } else if case .decrement = action {
                    expect.fulfill()
                }
            }
        )
        let spy = PublisherSpy(store)

        // When sending any increment
        store.send(.increment(10))

        // Then the increment should be decremented by the environment value
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }
}
