import Combine
import Roots
import XCTest

class StoreTests: XCTestCase {
    func testInitializeCountStore() {
        let store = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(store)
        store.send(.initialize)
        XCTAssertEqual(spy.values, [Count()])
    }

    func testActionsOnCountStore() {
        let store = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        store.send(.decrement(20))
        store.send(.initialize)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 0])
    }

    func testChildPingStore() {
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let spy = PublisherSpy(store)
        let pingStore = store.scope(to: \.ping, reducer: Count.reducer(state:action:))
        let pingSpy = PublisherSpy(pingStore)
        pingStore.send(.increment(10))
        pingStore.send(.decrement(20))
        pingStore.send(.initialize)
        let parentValues = spy.values.map(\.ping.count)
        let childValues = pingSpy.values.map(\.count)
        XCTAssertEqual(parentValues, [0, 10, -10, 0])
        XCTAssertEqual(childValues, [0, 10, -10, 0])
    }
}
