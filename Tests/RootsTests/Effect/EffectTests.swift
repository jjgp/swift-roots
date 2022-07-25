import Combine
import Roots
import XCTest

class ApplyEffectTests: XCTestCase {
    // TODO: test application of effect with transitions, subject, collection for cancellables
}

class CreateEffectTests: XCTestCase {
    // TODO: test static create effect methods
}

class EffectTests: XCTestCase {
    func testEffectsDirectly() {
        // TODO: come up with testing pattern for testing the effects in abscence of a store
    }
}

class EffectInScopeTests: XCTestCase {
    func testEffectsOfStoresInScope() {
        // Given a store that is scoped to two individual stores having the same increment/decrement effect
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let senderEffect: Effect<Count, Count.Action> = .subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(2 * value))
            }
        }
        let pingStore = store.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let pongStore = store.scope(
            to: \.pong,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let spy = PublisherSpy(store)
        let pingSpy = PublisherSpy(pingStore)
        let pongSpy = PublisherSpy(pongStore)

        // When each scoped store increments the values with a set sequence...
        pingStore.send(.increment(10))
        pongStore.send(.increment(10))
        pingStore.send(.increment(20))
        pongStore.send(.increment(20))
        pingStore.send(.increment(40))
        pongStore.send(.increment(40))
        // ...and the parent/global store sends an action to reset the state
        store.send(PingPong.initialize)

        // Then each store should emit values that are consistent with one another
        let values = spy.values.map { "\($0.ping.count), \($0.pong.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let pongValues = pongSpy.values.map(\.count)
        // Note that the ping/pong values are interleaved
        XCTAssertEqual(
            values,
            [
                "0, 0",
                "10, 0",
                "-10, 0",
                "-10, 10",
                "-10, -10",
                "10, -10",
                "-30, -10",
                "-30, 10",
                "-30, -30",
                "10, -30",
                "-70, -30",
                "-70, 10",
                "-70, -70",
                "0, 0",
            ]
        )
        XCTAssertEqual(pingValues, [0, 10, -10, 10, -30, 10, -70, 0])
        XCTAssertEqual(pongValues, [0, 10, -10, 10, -30, 10, -70, 0])
    }

    func testEffectsOfTwinStoresInScope() {
        // Given a store that is scoped to two twin stores having the same increment/decrement effect
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let senderEffect: Effect<Count, Count.Action> = .subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(2 * value))
            }
        }
        let pingStore = store.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let twinPingStore = store.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let spy = PublisherSpy(store)
        let pingSpy = PublisherSpy(pingStore)
        let twinPingSpy = PublisherSpy(twinPingStore)

        // When each scoped store increments the values with a set sequence...
        pingStore.send(.increment(10))
        twinPingStore.send(.increment(10))
        pingStore.send(.increment(20))
        twinPingStore.send(.increment(20))
        // ...and the parent/global store sends an action to reset the state
        store.send(PingPong.initialize)

        // Then the stores should all have a consistent view of the ping count
        let values = spy.values.map { "\($0.ping.count), \($0.pong.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let twinPingValues = twinPingSpy.values.map(\.count)
        XCTAssertEqual(
            values,
            [
                "0, 0",
                "10, 0",
                "-10, 0",
                "0, 0",
                "-20, 0",
                "0, 0",
                "-40, 0",
                "-20, 0",
                "-60, 0",
                "0, 0",
            ]
        )
        XCTAssertEqual(pingValues, [0, 10, -10, 0, -20, 0, -40, -20, -60, 0])
        XCTAssertEqual(twinPingValues, [0, 10, -10, 0, -20, 0, -40, -20, -60, 0])
    }
}
