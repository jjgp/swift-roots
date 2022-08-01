import Roots
import RootsTest
import XCTest

class StoreTopLevelTests: XCTestCase {
    func testInitializeCountStore() {
        // Given a store with a count state
        let sut = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(sut)

        // When initializing the state (an action that is redundant)
        sut.send(.initialize)

        // Then the state should not emit a subsequent new state (as it's a duplicate)
        XCTAssertEqual(spy.values, [Count()])
    }

    func testActionsOnCountStore() {
        // Given a store with a count state
        let sut = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(sut)

        // When actions are sent to increment/decrement/initialize
        sut.send(.increment(10))
        sut.send(.decrement(20))
        sut.send(.initialize)

        // Then the state values should reflect those actions
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 0])
    }

    func testActionsOfPingPongStoreOnCounts() {
        let sut = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let spy = PublisherSpy(sut)

        // When actions are sent to ping/pong/initialize
        sut.send(\.addToPing, 10)
        sut.send(\.addToPong, 20)
        sut.send(\.initialize)

        // Then the state values should reflect those actions
        let values = spy.values.map { "\($0.ping.count), \($0.pong.count)" }
        XCTAssertEqual(values, [
            "0, 0",
            "10, 0",
            "10, 20",
            "0, 0",
        ])
    }
}

class StoreInScopeTests: XCTestCase {
    func testScopedPingStore() {
        // Given a store and a scoped store
        let pingPongStore = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let sut = pingPongStore.scope(to: \.ping, reducer: Count.reducer(state:action:))

        let pingPongSpy = PublisherSpy(pingPongStore)
        let pingSpy = PublisherSpy(sut)

        // When sending actions to the scoped store
        sut.send(.increment(10))
        sut.send(.decrement(20))
        sut.send(.initialize)

        // Then each store should emit consistent state values
        let pintPongValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pintPongValues, [0, 10, -10, 0])
        XCTAssertEqual(pingValues, [0, 10, -10, 0])
    }

    func testActionsOfAllPingPongStoresInScope() {
        // Given a store and a scoped store
        let pingPongSUT = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let pingSUT = pingPongSUT.scope(to: \.ping, reducer: Count.reducer(state:action:))
        let pongSUT = pingPongSUT.scope(to: \.pong, reducer: Count.reducer(state:action:))

        let pingPongSpy = PublisherSpy(pingPongSUT)
        let pingSpy = PublisherSpy(pingSUT)
        let pongSpy = PublisherSpy(pongSUT)

        // When sending actions to all the scoped store
        pingSUT.send(.increment(10))
        pingPongSUT.send(\.addToPing, -20)
        pongSUT.send(.decrement(20))
        pingPongSUT.send(\.addToPong, 40)
        pingSUT.send(.initialize)
        pongSUT.send(.initialize)

        // Then each store should emit consistent state values
        let pintPongValues = pingPongSpy.values.map { "\($0.ping.count), \($0.pong.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let pongValues = pongSpy.values.map(\.count)
        XCTAssertEqual(pintPongValues, [
            "0, 0",
            "10, 0",
            "-10, 0",
            "-10, -20",
            "-10, 20",
            "0, 20",
            "0, 0",
        ])
        XCTAssertEqual(pingValues, [0, 10, -10, 0])
        XCTAssertEqual(pongValues, [0, -20, 20, 0])
    }
}
