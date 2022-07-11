import Combine
@testable import Roots
import XCTest

class EffectTests: XCTestCase {
    func testSynchronousEffect() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .senderEffect
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        store.send(.increment(20))
        store.send(.increment(40))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, 0, 20, 0, 40, 0])
    }

    func testAsynchronousEffect() {
        let expect = expectation(description: "The value is decremented")
        let effect: Effect<Count, Count.Action> = .sender { _, action, send in
            try? await Task.sleep(nanoseconds: 100)
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
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        wait(for: [expect], timeout: 1)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testPublisherEffect() {
        let store = Store(
            initialState: Count(),
            reducer: Count.reducer(state:action:),
            effect: .publisherEffect()
        )
        let spy = PublisherSpy(store.$state)
        store.send(.increment(10))
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -90])
    }

    func testEffectsOnChildrenStores() {
        let store = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let pingStore = store.store(
            from: \.ping,
            reducer: Count.reducer(state:action:),
            effect: .senderEffect
        )
        let pongStore = store.store(
            from: \.pong,
            reducer: Count.reducer(state:action:),
            effect: .senderEffect
        )
        let spy = PublisherSpy(store.$state)
        let pingSpy = PublisherSpy(pingStore.$state)
        let pongSpy = PublisherSpy(pongStore.$state)
        pingStore.send(.increment(10))
        pongStore.send(.increment(10))
        pingStore.send(.increment(20))
        pongStore.send(.increment(20))
        pingStore.send(.increment(40))
        pongStore.send(.increment(40))
        let values = spy.values.map { "\($0.ping.count), \($0.pong.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let pongValues = pongSpy.values.map(\.count)
        XCTAssertEqual(
            values,
            [
                "0, 0",
                "10, 0",
                "0, 0",
                "0, 10",
                "0, 0",
                "20, 0",
                "0, 0",
                "0, 20",
                "0, 0",
                "40, 0",
                "0, 0",
                "0, 40",
                "0, 0",
            ]
        )
        XCTAssertEqual(pingValues, [0, 10, 0, 20, 0, 40, 0])
        XCTAssertEqual(pongValues, [0, 10, 0, 20, 0, 40, 0])
    }

    func testTwinChildrenStates() {
        // TODO: this is not currently supported
    }
}

private extension Effect where S == Count, A == Count.Action {
    static var senderEffect: Self {
        .sender { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(value))
            }
        }
    }

    static func publisherEffect() -> Self {
        .publisher { actionPairPublisher in
            actionPairPublisher
                .filter(action: .increment(10))
                .map(to: .decrement(100))
        }
    }
}
