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

    func testEffectsOfStoresInScope() {
        // Given a store that is scoped to the individual Count stores having the same increment/decrement effect
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStore.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: ApplyEffects(.decrementByDoubleIncrementedValue())
        )
        let secondCountStore = countsStore.scope(
            to: \.second,
            reducer: Count.reducer(state:action:),
            middleware: ApplyEffects(.decrementByDoubleIncrementedValue())
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
        countsStore.send(Counts.Initialize())

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
        // Given a store that is scoped to two twin state having the same increment/decrement effect
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStore.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: ApplyEffects(.decrementByDoubleIncrementedValue())
        )
        let otherFirstCountStore = countsStore.scope(
            to: \.first,
            reducer: Count.reducer(state:action:),
            middleware: ApplyEffects(.decrementByDoubleIncrementedValue())
        )

        let countsSpy = PublisherSpy(countsStore)
        let firstCountSpy = PublisherSpy(firstCountStore)
        let otherFirstCountSpy = PublisherSpy(otherFirstCountStore)

        // When each scoped store increments the values with a set sequence...
        firstCountStore.send(.increment(10))
        otherFirstCountStore.send(.increment(10))
        firstCountStore.send(.increment(20))
        otherFirstCountStore.send(.increment(20))
        // ...and the parent/global store sends an action to reset the state
        countsStore.send(Counts.Initialize())

        // Then the stores should all have a consistent view of the ping count
        let countsValues = countsSpy.values.map { "\($0.first.count), \($0.second.count)" }
        let firstCountValues = firstCountSpy.values.map(\.count)
        let otherFirstCountValues = otherFirstCountSpy.values.map(\.count)
        XCTAssertEqual(
            countsValues,
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
        XCTAssertEqual(firstCountValues, [0, 10, -10, 0, -20, 0, -40, -20, -60, 0])
        XCTAssertEqual(otherFirstCountValues, [0, 10, -10, 0, -20, 0, -40, -20, -60, 0])
    }
}

private extension Effect where State == Count, Action == Count.Action {
    static func decrementByIncrementedValue() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                if case let .increment(value) = action {
                    return .decrement(value)
                } else {
                    return nil
                }
            }
        }
    }

    static func decrementByDoubleIncrementedValue() -> Self {
        Effect { _, actions in
            actions.compactMap { action in
                if case let .increment(value) = action {
                    return .decrement(2 * value)
                } else {
                    return nil
                }
            }
        }
    }
}
