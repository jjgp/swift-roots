import Roots
import RootsTest
import XCTest

class StateBindingTests: XCTestCase {
    func testBindingInScope() {
        // Given a state binding that is scoped to a nested state
        let counts = Counts()
        let countsStateBinding = StateBinding(initialState: counts)
        let firstCountStateBinding = countsStateBinding.scope(\.first)

        let countsSpy = PublisherSpy(countsStateBinding)
        let firstCountSpy = PublisherSpy(firstCountStateBinding)

        // When either binding is mutated
        firstCountStateBinding.wrappedState.count = 42
        countsStateBinding.wrappedState.first.count = 21
        firstCountStateBinding.wrappedState.count = 1337

        // Then each view of the state should be consistent with the other
        let countsValues = countsSpy.values.map(\.first.count)
        let firstCountValues = firstCountSpy.values.map(\.count)
        XCTAssertEqual(countsValues, [0, 42, 21, 1337])
        XCTAssertEqual(firstCountValues, [0, 42, 21, 1337])
    }

    func testTwinBindingsInScope() {
        // Given a state binding that is scoped to twin nested states
        let counts = Counts()
        let countsStateBinding = StateBinding(initialState: counts)
        let firstCountStateBinding = countsStateBinding.scope(\.first)
        let otherFirstCountStateBinding = countsStateBinding.scope(\.first)

        let countsSpy = PublisherSpy(countsStateBinding)
        let firstCountSpy = PublisherSpy(firstCountStateBinding)
        let otherFirstCountSpy = PublisherSpy(otherFirstCountStateBinding)

        // When any binding is mutated
        firstCountStateBinding.wrappedState.count = 42
        otherFirstCountStateBinding.wrappedState.count -= 42
        countsStateBinding.wrappedState.first.count = 21
        otherFirstCountStateBinding.wrappedState.count -= 21
        firstCountStateBinding.wrappedState.count = 1337
        otherFirstCountStateBinding.wrappedState.count -= 1337

        // Then any view of the state should be consistent with the other
        let countValues = countsSpy.values.map(\.first.count)
        let firstCountValues = firstCountSpy.values.map(\.count)
        let otherFirstCountValues = otherFirstCountSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(firstCountValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(otherFirstCountValues, [0, 42, 0, 21, 0, 1337, 0])
    }

    func testPredicateRemovesDuplicates() {
        // Given a state binding with a predicate
        let countStateBinding = StateBinding(initialState: Count(), predicate: ==)
        let countSpy = PublisherSpy(countStateBinding)

        // When duplicate states are set
        countStateBinding.wrappedState.count = 42
        countStateBinding.wrappedState.count = 42

        // Then the duplicate states should not be published
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 42])
    }

    func testEquatableStateRemovesDuplicates() {
        // Given a state binding to a state that is Equatable
        let countStateBinding = StateBinding(initialState: Count())
        let countSpy = PublisherSpy(countStateBinding)

        // When duplicate states are set
        countStateBinding.wrappedState.count = 42
        countStateBinding.wrappedState.count = 42

        // Then the duplicate states should not be published
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 42])
    }
}
