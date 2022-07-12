import Combine
import Roots
import XCTest

// TODO: convert to Publisher
struct CurrentStateSubject<S: State> {
    var wrappedState: S {
        get { getState() }
        nonmutating set { setState(newValue) }
    }

    private let getState: () -> S
    private let setState: (S) -> Void

    init(getState: @escaping () -> S, setState: @escaping (S) -> Void) {
        self.getState = getState
        self.setState = setState
    }
}

extension CurrentStateSubject: Publisher {
    func receive<Subscriber: Combine.Subscriber>(
        subscriber _: Subscriber
    ) where Failure == Subscriber.Failure, Output == Subscriber.Input {}

    typealias Failure = Never
    typealias Output = S
}

extension CurrentStateSubject {
    init(wrappedState: S) {
        var wrappedState = wrappedState
        self.init(getState: { wrappedState }, setState: { wrappedState = $0 })
    }
}

extension CurrentStateSubject {
    func map<ChildS: State>(_ keyPath: WritableKeyPath<S, ChildS>) -> CurrentStateSubject<ChildS> {
        CurrentStateSubject<ChildS>(
            getState: { wrappedState[keyPath: keyPath] },
            setState: { wrappedState[keyPath: keyPath] = $0 }
        )
    }
}

class CurrentStateSubjectTests: XCTestCase {
    func testCurrentValueSubject() {
        let subject = CurrentValueSubject<Count, Never>(Count())
        let spy = PublisherSpy(subject)
        subject.value.count = 1337
        subject.send(Count(count: 42))
        let values = spy.values.map(\.count)
        XCTAssertEqual([0, 42], values)
    }

    func testWrappedState() {
        var count = Count()
        let subject = CurrentStateSubject(wrappedState: count)
        count.count += 1
        subject.wrappedState = count

        XCTAssertEqual(count, subject.wrappedState)
    }

    func testMappedBinding() {
        let pingPong = PingPong()
        let pingPongBinding = CurrentStateSubject(wrappedState: pingPong)
        let pingBinding = pingPongBinding.map(\.ping)
        pingBinding.wrappedState = Count(count: 42)

        XCTAssertEqual(pingPongBinding.wrappedState.ping, pingBinding.wrappedState)
    }
}
