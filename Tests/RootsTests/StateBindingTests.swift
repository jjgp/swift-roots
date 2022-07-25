@testable import Roots
import RootsTest
import XCTest

class StateBindingTests: XCTestCase {
    func testBindingInScope() {
        // Given a state binding that is scoped to a nested state
        let pingPong = PingPong()
        let pingPongBinding = StateBinding(initialState: pingPong)
        let pingBinding = pingPongBinding.scope(\.ping)
        let pingPongSpy = PublisherSpy(pingPongBinding)
        let pingSpy = PublisherSpy(pingBinding)

        // When either binding is mutated
        pingBinding.wrappedState.count = 42
        pingPongBinding.wrappedState.ping.count = 21
        pingBinding.wrappedState.count = 1337

        // Then each view of the state should be consistent with the other
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 21, 1337])
        XCTAssertEqual(pingValues, [0, 42, 21, 1337])
    }

    func testTwinBindingsInScope() {
        // Given a state binding that is scoped to twin nested states
        let pingPong = PingPong()
        let pingPongBinding = StateBinding(initialState: pingPong)
        let pingBinding = pingPongBinding.scope(\.ping)
        let twinPingBinding = pingPongBinding.scope(\.ping)
        let pingPongSpy = PublisherSpy(pingPongBinding)
        let pingSpy = PublisherSpy(pingBinding)
        let twinPingSpy = PublisherSpy(twinPingBinding)

        // When any binding is mutated
        pingBinding.wrappedState.count = 42
        twinPingBinding.wrappedState.count -= 42
        pingPongBinding.wrappedState.ping.count = 21
        twinPingBinding.wrappedState.count -= 21
        pingBinding.wrappedState.count = 1337
        twinPingBinding.wrappedState.count -= 1337

        // Then any view of the state should be consistent with the other
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        let twinPingValues = twinPingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(pingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(twinPingValues, [0, 42, 0, 21, 0, 1337, 0])
    }
}
