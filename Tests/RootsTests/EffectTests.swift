import Combine
@testable import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let effect = Effect<Count> {}
        let store = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(store.$state)
        store.send(.initialize)
        XCTAssertEqual(spy.values, [Count(), Count()])
    }
}
