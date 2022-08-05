import Roots
import RootsTest
import XCTest

class StateBindingTests: XCTestCase {
    func testBindingInScope() {
        // Given a state binding that is scoped to a nested state
        let pingPong = PingPong()

        let pingPongSUT = StateBinding(initialState: pingPong)
        let pingSUT = pingPongSUT.scope(\.ping)

        let pingPongSpy = PublisherSpy(pingPongSUT)
        let pingSpy = PublisherSpy(pingSUT)

        // When either binding is mutated
        pingSUT.wrappedState.count = 42
        pingPongSUT.wrappedState.ping.count = 21
        pingSUT.wrappedState.count = 1337

        // Then each view of the state should be consistent with the other
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 21, 1337])
        XCTAssertEqual(pingValues, [0, 42, 21, 1337])
    }

    func testTwinBindingsInScope() {
        // Given a state binding that is scoped to twin nested states
        let pingPong = PingPong()

        let pingPongSUT = StateBinding(initialState: pingPong)
        let pingSUT = pingPongSUT.scope(\.ping)
        let twinPingSUT = pingPongSUT.scope(\.ping)

        let pingPongSpy = PublisherSpy(pingPongSUT)
        let pingSpy = PublisherSpy(pingSUT)
        let twinPingSpy = PublisherSpy(twinPingSUT)

        // When any binding is mutated
        pingSUT.wrappedState.count = 42
        twinPingSUT.wrappedState.count -= 42
        pingPongSUT.wrappedState.ping.count = 21
        twinPingSUT.wrappedState.count -= 21
        pingSUT.wrappedState.count = 1337
        twinPingSUT.wrappedState.count -= 1337

        // Then any view of the state should be consistent with the other
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        let twinPingValues = twinPingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(pingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(twinPingValues, [0, 42, 0, 21, 0, 1337, 0])
    }

    func testPredicateRemovesDuplicates() {
        // Given a state binding with a predicate
        let sut = StateBinding(initialState: Count(), predicate: ==)
        let spy = PublisherSpy(sut)

        // When duplicate states are set
        sut.wrappedState.count = 42
        sut.wrappedState.count = 42

        // Then the duplicate states should not be published
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 42])
    }

    func testEquatableStateRemovesDuplicates() {
        // Given a state binding to a state that is Equatable
        let sut = StateBinding(initialState: Count())
        let spy = PublisherSpy(sut)

        // When duplicate states are set
        sut.wrappedState.count = 42
        sut.wrappedState.count = 42

        // Then the duplicate states should not be published
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 42])
    }
}
