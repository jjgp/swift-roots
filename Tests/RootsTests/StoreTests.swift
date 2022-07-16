import Combine
import Roots
import XCTest

class StoreTests: XCTestCase {
    func testInitializeCountStore() {
        // Given a store with a count state
        let store = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(store)

        // When initializing the state (an action that is redundant)
        store.send(.initialize)

        // Then the state should not emit a subsequent new state (as it's a duplicate)
        XCTAssertEqual(spy.values, [Count()])
    }

    func testActionsOnCountStore() {
        // Given a store with a count state
        let store = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(store)

        // When actions are sent to increment/decrement/initialize
        store.send(.increment(10))
        store.send(.decrement(20))
        store.send(.initialize)

        // Then the state values should reflect those actions
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 0])
    }

    func testScopedPingStore() {
        // Given a store and a scoped store
        let pingPongStore = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let pingPongspy = PublisherSpy(pingPongStore)
        let pingStore = pingPongStore.scope(to: \.ping, reducer: Count.reducer(state:action:))
        let pingSpy = PublisherSpy(pingStore)

        // When sending actions to the scoped store
        pingStore.send(.increment(10))
        pingStore.send(.decrement(20))
        pingStore.send(.initialize)

        // Then each store should emit consistent state values
        let pintPongValues = pingPongspy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pintPongValues, [0, 10, -10, 0])
        XCTAssertEqual(pingValues, [0, 10, -10, 0])
    }
}
