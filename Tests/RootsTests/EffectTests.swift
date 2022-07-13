import Combine
import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .sender { _, action, send in
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

    func testAsynchronousEffect() {
        let expect = expectation(description: "The value is decremented")
        let effect: Effect<Count, Count.Action> = .sender { _, action, send in
            if case .increment = action {
                await MainActor.run {
                    send(.decrement(100))
                }
            } else if case .decrement = action {
                expect.fulfill()
            }
        }
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: effect
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testPublisherEffect() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .publisher { actionPairPublisher in
                actionPairPublisher
                    .filter { $0.action == .increment(10) }
                    .map { _ in .decrement(100) }
            }
        )
        let spy = PublisherSpy(store)
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testEffectsOnStoresInScope() {
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let senderEffect: Effect<Count, Count.Action> = .sender { _, action, send in
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
        pingStore.send(.increment(10))
        pongStore.send(.increment(10))
        pingStore.send(.increment(20))
        pongStore.send(.increment(20))
        pingStore.send(.increment(40))
        pongStore.send(.increment(40))
        store.send(.initialize)
        let values = spy.values.map { "\($0.ping.count), \($0.pong.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let pongValues = pongSpy.values.map(\.count)
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

    func testTwinStoresInScope() {
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let senderEffect: Effect<Count, Count.Action> = .sender { _, action, send in
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
        pingStore.send(.increment(10))
        twinPingStore.send(.increment(10))
        pingStore.send(.increment(20))
        twinPingStore.send(.increment(20))
        store.send(.initialize)
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
