@testable import Roots
import XCTest

class StateBindingTests: XCTestCase {
    func testWrappedState() {
        var count = Count()
        let binding = StateBinding(initialState: count)
        count.count += 1
        binding.wrappedState = count

        XCTAssertEqual(count, binding.wrappedState)
    }

    func testBindingInScope() {
        let pingPong = PingPong()
        let pingPongBinding = StateBinding(initialState: pingPong)
        let pingBinding = pingPongBinding.scope(\.ping)
        let pingPongSpy = PublisherSpy(pingPongBinding)
        let pingSpy = PublisherSpy(pingBinding)
        pingBinding.wrappedState.count = 42
        pingPongBinding.wrappedState.ping.count = 21
        pingBinding.wrappedState.count = 1337
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 21, 1337])
        XCTAssertEqual(pingValues, [0, 42, 21, 1337])
    }

    func testTwinBindingsInScope() {
        let pingPong = PingPong()
        let pingPongBinding = StateBinding(initialState: pingPong)
        let pingBinding = pingPongBinding.scope(\.ping)
        let twinPingBinding = pingPongBinding.scope(\.ping)
        let pingPongSpy = PublisherSpy(pingPongBinding)
        let pingSpy = PublisherSpy(pingBinding)
        let twinPingSpy = PublisherSpy(twinPingBinding)
        pingBinding.wrappedState.count = 42
        twinPingBinding.wrappedState.count -= 42
        pingPongBinding.wrappedState.ping.count = 21
        twinPingBinding.wrappedState.count -= 21
        pingBinding.wrappedState.count = 1337
        twinPingBinding.wrappedState.count -= 1337
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        let twinPingValues = twinPingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(pingValues, [0, 42, 0, 21, 0, 1337, 0])
        XCTAssertEqual(twinPingValues, [0, 42, 0, 21, 0, 1337, 0])
    }
}
