import Combine
import XCTest

class MiddlewareTests: XCTestCase {
    func test() {
        let pub = PassthroughSubject<(Int, Int), Never>()
        let sub = pub.sink { foo, _ in
            print(foo)
        }
        sub.cancel()
    }
}
