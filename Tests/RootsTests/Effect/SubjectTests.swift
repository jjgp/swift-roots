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
}
