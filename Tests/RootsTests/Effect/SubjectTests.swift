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

    func testAsyncSubjectEffect() {}

    func testAsyncSubjectEffectOfEnvironment() {}
}
