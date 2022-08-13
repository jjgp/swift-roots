@testable import Roots
import XCTest

class OneAtATimeSendSchedulerTests: XCTestCase {
    func testRecursiveSendingIsBuffered() {
        // Given a OneAtATimeSendScheduler
        let sendScheduler = BarrierSendScheduler()

        var actions = [String]()
        var send: Dispatch<String>!
        send = { action in
            actions.append(action)
            if action == "foo" {
                sendScheduler.schedule(action: "bar", sendingTo: send)
                sendScheduler.schedule(action: "baz", sendingTo: send)
                XCTAssertEqual(sendScheduler.sendPendingBuffer.count, 2)
            } else if action == "bar" {
                XCTAssertEqual(sendScheduler.sendPendingBuffer.count, 1)
            } else if action == "baz" {
                XCTAssertEqual(sendScheduler.sendPendingBuffer.count, 0)
            }
        }

        // When an action is sent that triggers recursive actions
        // Then the other actions should be bufferred to allow for the others to complete
        sendScheduler.schedule(action: "foo", sendingTo: send)
        XCTAssertEqual(actions, ["foo", "bar", "baz"])
    }
}
