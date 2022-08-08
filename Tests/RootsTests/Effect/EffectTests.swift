import Roots
import RootsTest
import XCTest

class EffectTests: XCTestCase {
    func testEffect() {
        // Given an effect that maps increments to decrements
        let spy = EffectSpy(.decrementByIncrementedValue())

        // When an increment is sent
        spy.send(state: .init(), action: .increment(10))

        // Then the a decrement action should be sent
        XCTAssertEqual(spy.values, [.decrement(10)])
    }
}

class EffectsOfStoreInScopeTests: XCTestCase {
    func testEffectsOfStoresInScope() {
        // Given a store that is scoped to the individual Count stores having the same increment/decrement effect
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))

        let firstCountStore = countsStore.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: apply(effects: .decrementByDoubleIncrementedValue())
        )
        let secondCountStore = countsStore.scope(
            to: \.second,
            reducer: Count.reducer(state:action:),
            middleware: apply(effects: .decrementByDoubleIncrementedValue())
        )

        let countsSpy = PublisherSpy(countsStore)
        let firstCountSpy = PublisherSpy(firstCountStore)
        let secondCountSpy = PublisherSpy(secondCountStore)

        // When each scoped store increments the values with a set sequence...
        firstCountStore.send(.increment(10))
        secondCountStore.send(.increment(10))
        firstCountStore.send(.increment(20))
        secondCountStore.send(.increment(20))
        firstCountStore.send(.increment(40))
        secondCountStore.send(.increment(40))
        // ...and the parent store sends an action to reset the state
        countsStore.send(creator: \.initialize)

        // Then each store should emit values that are consistent with one another
        let countsValues = countsSpy.values.map { [$0.first.count, $0.second.count] }
        let firstCountValues = firstCountSpy.values.map(\.count)
        let secondCountValues = secondCountSpy.values.map(\.count)
        // Note that the first/second values are interleaved
        XCTAssertEqual(
            countsValues,
            [
                [0, 0],
                [10, 0],
                [-10, 0],
                [-10, 10],
                [-10, -10],
                [10, -10],
                [-30, -10],
                [-30, 10],
                [-30, -30],
                [10, -30],
                [-70, -30],
                [-70, 10],
                [-70, -70],
                [0, 0],
            ]
        )
        XCTAssertEqual(firstCountValues, [0, 10, -10, 10, -30, 10, -70, 0])
        XCTAssertEqual(secondCountValues, [0, 10, -10, 10, -30, 10, -70, 0])
    }

    func testEffectsOfTwinStoresInScope() {
        // Given a store that is scoped to two twin stores having the same increment/decrement effect
        let pingPongSUT = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))

        let pingSUT = pingPongSUT.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: apply(effects: .decrementByDoubleIncrementedValue())
        )
        let twinPingSUT = pingPongSUT.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: apply(effects: .decrementByDoubleIncrementedValue())
        )

        let pintPongSpy = PublisherSpy(pingPongSUT)
        let pingSpy = PublisherSpy(pingSUT)
        let twinPingSpy = PublisherSpy(twinPingSUT)

        // When each scoped store increments the values with a set sequence...
        pingSUT.send(.increment(10))
        twinPingSUT.send(.increment(10))
        pingSUT.send(.increment(20))
        twinPingSUT.send(.increment(20))
        // ...and the parent/global store sends an action to reset the state
        pingPongSUT.send(creator: \.initialize)

        // Then the stores should all have a consistent view of the ping count
        let pingPongValues = pintPongSpy.values.map { "\($0.first.count), \($0.second.count)" }
        let pingValues = pingSpy.values.map(\.count)
        let twinPingValues = twinPingSpy.values.map(\.count)
        XCTAssertEqual(
            pingPongValues,
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

private extension Effect where State == Count, Action == Count.Action {
    static func decrementByIncrementedValue() -> Self {
        Effect { transitionPublisher in
            let publisher = transitionPublisher.compactMap { transition -> Count.Action? in
                if case let .increment(value) = transition.action {
                    return .decrement(value)
                } else {
                    return nil
                }
            }

            return [Cause](publisher)
        }
    }

    static func decrementByDoubleIncrementedValue() -> Self {
        .subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(2 * value))
            }
        }
    }
}
