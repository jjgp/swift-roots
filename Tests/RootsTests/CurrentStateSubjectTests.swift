import Combine
import Roots
import XCTest

struct CurrentStatePublisher<S: State> {
    var wrappedState: S {
        get { getState() }
        nonmutating set { setState(newValue) }
    }

    private let getState: () -> S
    private let setState: (S) -> Void
    private let getPublisher: () -> AnyPublisher<S, Never>
    private let setSubscriber: (AnySubscriber<S, Never>) -> Void

    private init(
        getPublisher: @escaping () -> AnyPublisher<S, Never>,
        getState: @escaping () -> S,
        setState: @escaping (S) -> Void,
        setSubscriber: @escaping (AnySubscriber<S, Never>) -> Void
    ) {
        self.getPublisher = getPublisher
        self.getState = getState
        self.setState = setState
        self.setSubscriber = setSubscriber
    }
}

extension CurrentStatePublisher: Publisher {
    func receive<Subscriber: Combine.Subscriber>(
        subscriber: Subscriber
    ) where Failure == Subscriber.Failure, Output == Subscriber.Input {
        setSubscriber(AnySubscriber(subscriber))
    }

    typealias Failure = Never
    typealias Output = S
}

extension CurrentStatePublisher {
    init(initialState: S) {
        let subject = CurrentValueSubject<S, Never>(initialState)
        self.init(
            getPublisher: { subject.eraseToAnyPublisher() },
            getState: { subject.value },
            setState: { subject.value = $0 },
            setSubscriber: { subject.receive(subscriber: $0) }
        )
    }
}

extension CurrentStatePublisher {
    func map<ChildS: State>(_ keyPath: WritableKeyPath<S, ChildS>) -> CurrentStatePublisher<ChildS> {
        let publisher = getPublisher().map(keyPath)
        return CurrentStatePublisher<ChildS>(
            getPublisher: { publisher.eraseToAnyPublisher() },
            getState: { wrappedState[keyPath: keyPath] },
            setState: { wrappedState[keyPath: keyPath] = $0 },
            setSubscriber: { publisher.receive(subscriber: $0) }
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
        XCTAssertEqual([0, 1337, 42], values)
    }

    func testWrappedState() {
        var count = Count()
        let subject = CurrentStatePublisher(initialState: count)
        count.count += 1
        subject.wrappedState = count

        XCTAssertEqual(count, subject.wrappedState)
    }

    func testMappedBinding() {
        let pingPong = PingPong()
        let pingPongSubject = CurrentStatePublisher(initialState: pingPong)
        let pingSubject = pingPongSubject.map(\.ping)
        let pingPongSpy = PublisherSpy(pingPongSubject)
        let pingSpy = PublisherSpy(pingSubject)
        pingSubject.wrappedState.count = 42
        pingPongSubject.wrappedState.ping.count = 21
        pingSubject.wrappedState.count = 1337
        let pingPongPingValues = pingPongSpy.values.map(\.ping.count)
        let pingValues = pingSpy.values.map(\.count)
        XCTAssertEqual(pingPongPingValues, [0, 42, 21, 1337])
        XCTAssertEqual(pingValues, [0, 42, 21, 1337])
    }
}
