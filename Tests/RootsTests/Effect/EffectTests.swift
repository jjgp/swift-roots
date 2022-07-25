import Roots
import RootsTest
import XCTest

class EffectTests: XCTestCase {
    func testEffect() {
        // Given an effect that maps increments to decrements
        let spy = EffectSpy(Effect<Count, Count.Action> { transitionPublisher in
            [
                transitionPublisher.compactMap { transition in
                    if case let .increment(value) = transition.action {
                        return .decrement(value)
                    } else {
                        return nil
                    }
                }.toEffectArtifact(),
            ]
        })

        // When an increment is sent
        spy.send(state: .init(), action: .increment(10))

        // Then the a decrement action should be sent
        XCTAssertEqual(spy.values, [.decrement(10)])
    }
}

class EffectsOfStoreInScopeTests: XCTestCase {
    func testEffectsOfStoresInScope() {
        // Given a store that is scoped to two individual stores having the same increment/decrement effect
        let sut = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))

        let senderEffect: Effect<Count, Count.Action> = .subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(2 * value))
            }
        }
        let pingSUT = sut.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let pongSUT = sut.scope(
            to: \.pong,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )

        let spy = PublisherSpy(sut)
        let pingSpy = PublisherSpy(pingSUT)
        let pongSpy = PublisherSpy(pongSUT)

        // When each scoped store increments the values with a set sequence...
        pingSUT.send(.increment(10))
        pongSUT.send(.increment(10))
        pingSUT.send(.increment(20))
        pongSUT.send(.increment(20))
        pingSUT.send(.increment(40))
        pongSUT.send(.increment(40))
        // ...and the parent/global store sends an action to reset the state
        sut.send(PingPong.initialize)

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
        let sut = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))

        let senderEffect: Effect<Count, Count.Action> = .subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(2 * value))
            }
        }

        let pingSUT = sut.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )
        let twinPingSUT = sut.scope(
            to: \.ping,
            reducer: Count.reducer(state:action:),
            effect: senderEffect
        )

        let spy = PublisherSpy(sut)
        let pingSpy = PublisherSpy(pingSUT)
        let twinPingSpy = PublisherSpy(twinPingSUT)

        // When each scoped store increments the values with a set sequence...
        pingSUT.send(.increment(10))
        twinPingSUT.send(.increment(10))
        pingSUT.send(.increment(20))
        twinPingSUT.send(.increment(20))
        // ...and the parent/global store sends an action to reset the state
        sut.send(PingPong.initialize)

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
