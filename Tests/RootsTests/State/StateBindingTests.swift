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

    func testMappedBinding() {
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
}
