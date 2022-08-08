import Roots
import RootsTest
import XCTest

class StoreTests: XCTestCase {
    func testNonEquatableStore() {}

    func testInitializeCountStore() {
        // Given a store with a Count state
        let countStore = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        // When initializing the state (an action that is redundant)
        countStore.send(.initialize)

        // Then the state should not emit a subsequent new state (as it's a duplicate)
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0])
    }

    func testActionsOnCountStore() {
        // Given a store with a Count state
        let countStore = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        // When actions are sent to increment/decrement/initialize
        countStore.send(.increment(10))
        countStore.send(.decrement(20))
        countStore.send(.initialize)

        // Then the state values should reflect those actions
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 10, -10, 0])
    }

    func testActionsOnCountsStore() {
        // Given a store with a Counts state
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let countsSpy = PublisherSpy(countsStore)

        // When actions are sent to to add and to initialize
        countsStore.send(creator: \.addToCount, passing: \.first, 10)
        countsStore.send(creator: \.addToCount, passing: \.second, 20)
        countsStore.send(creator: \.initialize)

        // Then the state values should reflect those actions
        let countsValues = countsSpy.values.map { [$0.first.count, $0.second.count] }
        XCTAssertEqual(countsValues, [
            [0, 0],
            [10, 0],
            [10, 20],
            [0, 0],
        ])
    }

    func testToAnyStateContainer() {}

    func testStoreInNonEquatableScope() {}

    func testStoreInFirstCountScope() {
        // Given a store scoped to the first Count state
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStore.scope(to: \.first, reducer: Count.reducer(state:action:))

        let countsSpy = PublisherSpy(countsStore)
        let firstCountSpy = PublisherSpy(firstCountStore)

        // When sending actions to the scoped store
        firstCountStore.send(.increment(10))
        firstCountStore.send(.decrement(20))
        firstCountStore.send(.initialize)

        // Then each store should emit consistent state values
        let countsValues = countsSpy.values.map(\.first.count)
        let firstCountValues = firstCountSpy.values.map(\.count)
        XCTAssertEqual(countsValues, [0, 10, -10, 0])
        XCTAssertEqual(firstCountValues, [0, 10, -10, 0])
    }

    func testAllCountsStoresInScope() {
        // Given a all Count(s) stores
        let countsStores = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStores.scope(to: \.first, reducer: Count.reducer(state:action:))
        let secondCountStore = countsStores.scope(to: \.second, reducer: Count.reducer(state:action:))

        let countsSpy = PublisherSpy(countsStores)
        let firstCountSpy = PublisherSpy(firstCountStore)
        let secondCountSpy = PublisherSpy(secondCountStore)

        // When sending actions to all stores
        firstCountStore.send(.increment(10))
        countsStores.send(creator: \.addToCount, passing: \.first, -20)
        secondCountStore.send(.decrement(20))
        countsStores.send(creator: \.addToCount, passing: \.second, 40)
        firstCountStore.send(.initialize)
        secondCountStore.send(.initialize)

        // Then each store should emit consistent state values
        let countsValues = countsSpy.values.map { [$0.first.count, $0.second.count] }
        let firstCountValues = firstCountSpy.values.map(\.count)
        let secondCountValues = secondCountSpy.values.map(\.count)
        XCTAssertEqual(countsValues, [
            [0, 0],
            [10, 0],
            [-10, 0],
            [-10, -20],
            [-10, 20],
            [0, 20],
            [0, 0],
        ])
        XCTAssertEqual(firstCountValues, [0, 10, -10, 0])
        XCTAssertEqual(secondCountValues, [0, -20, 20, 0])
    }
}
