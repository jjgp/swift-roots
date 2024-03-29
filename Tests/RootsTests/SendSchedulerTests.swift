@testable import Roots
import XCTest

class OneAtATimeSendSchedulerTests: XCTestCase {
    func testRecursiveSendingIsBuffered() {
        // Given a OneAtATimeSendScheduler
        let sendScheduler = BufferedRecursionSendScheduler()

        var actions = [String]()
        var send: Dispatch<String>!
        send = { action in
            actions.append(action)
            if action == "foo" {
                sendScheduler.schedule(action: "bar", sendingTo: send)
                sendScheduler.schedule(action: "baz", sendingTo: send)
            }
        }

        // When an action is sent that triggers recursive actions
        // Then the other actions should be bufferred to allow for the others to complete
        sendScheduler.schedule(action: "foo", sendingTo: send)
        XCTAssertEqual(actions, ["foo", "bar", "baz"])
    }
}
