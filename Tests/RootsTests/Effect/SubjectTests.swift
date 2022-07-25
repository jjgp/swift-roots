import Roots
import RootsTest
import XCTest

class SubjectEffectTests: XCTestCase {
    func testSubjectEffect() {
        // Given a subject effect that decrements any incremented value
        let spy = EffectSpy<Count, Count.Action>(.subject { _, action, send in
            if case let .increment(value) = action {
                send(.decrement(value))
            }
        })

        // When sending any increments
        spy.send(state: .init(count: 10), action: .increment(10))
        spy.send(state: .init(count: 20), action: .increment(20))
        // This action should be unaffected
        spy.send(state: .init(count: 0), action: .decrement(40))

        // Then those increments should be decremented back to 0
        XCTAssertEqual(spy.values, [.decrement(10), .decrement(20)])
    }

    func testAsyncSubjectEffect() {
        // Given a subject effect that decrements any incremented value
        let expect = expectation(description: "Action is sent on main queue")
        let spy = EffectSpy<Count, Count.Action>(.subject { _, action, send in
            if case let .increment(value) = action {
                await MainActor.run {
                    send(.decrement(value))
                    expect.fulfill()
                }
            }
        })

        // When sending an increment
        spy.send(state: .init(count: 10), action: .increment(10))

        wait(for: [expect], timeout: 1)

        // Then that increment should be decremented back to 0
        XCTAssertEqual(spy.values, [.decrement(10)])
    }
}
