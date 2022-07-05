import Combine
@testable import Roots
import XCTest

class StoreTests: XCTestCase {
    func testInitialize() {
        let sut = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(sut.$state)
        sut.send(.initialize)
        XCTAssertEqual(spy.values, [Count(), Count()])
    }

    func testUpdatingCount() {
        let sut = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let spy = PublisherSpy(sut.$state)
        sut.send(.increment(10))
        sut.send(.decrement(20))
        sut.send(.initialize)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 0])
    }

    func testParentAndChildStores() {
        let parentSUT = Store(initialState: PingPong(), reducer: PingPong.reducer(state:action:))
        let parentSpy = PublisherSpy(parentSUT.$state)
        let childSUT = parentSUT.store(from: \.ping, reducer: Count.reducer(state:action:))
        let childSpy = PublisherSpy(childSUT.$state)
        childSUT.send(.increment(10))
        childSUT.send(.decrement(20))
        childSUT.send(.initialize)
        let parentValues = parentSpy.values.map(\.ping.count)
        let childValues = childSpy.values.map(\.count)
        XCTAssertEqual(parentValues, [0, 10, -10, 0])
        XCTAssertEqual(childValues, [0, 10, -10, 0])
    }
}

// MARK: Spy

private class PublisherSpy<P: Publisher> {
    private var cancellable: AnyCancellable!
    private(set) var failure: P.Failure?
    private(set) var finished = false
    private(set) var values: [P.Output] = []

    init(_ publisher: P) {
        cancellable = publisher.sink(
            receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.finished = false
                case let .failure(error):
                    self?.failure = error
                }
            },
            receiveValue: { [weak self] value in
                self?.values.append(value)
            }
        )
    }
}
