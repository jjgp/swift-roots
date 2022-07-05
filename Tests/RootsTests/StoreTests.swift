import Combine
@testable import Roots
import XCTest

class StoreTests: XCTestCase {
    func testInitialize() {
        let sut = makeSut(initialState: Count())
        let spy = PublisherSpy(sut.statePublisher)
        sut.send(.initialize)
        XCTAssertEqual(spy.values, [Count(), Count()])
    }

    func testUpdatingCount() {
        let sut = makeSut(initialState: Count())
        let spy = PublisherSpy(sut.statePublisher)
        sut.send(.increment(10))
        sut.send(.decrement(20))
        sut.send(.initialize)
        let values = spy.values.map(\.count)
        XCTAssertEqual(values, [0, 10, -10, 0])
    }

    func testParentAndChildStores() {
        let parentSUT = makeSut(initialState: PingPong())
        let parentSpy = PublisherSpy(parentSUT.statePublisher)
        let childSUT = parentSUT.store(from: \.ping)
        let childSpy = PublisherSpy(childSUT.statePublisher)
        childSUT.send(.increment(10))
        childSUT.send(.decrement(20))
        childSUT.send(.initialize)
        let parentValues = parentSpy.values.map(\.ping.count)
        let childValues = childSpy.values.map(\.count)
        XCTAssertEqual(parentValues, [0, 10, -10, 0])
        XCTAssertEqual(childValues, [0, 10, -10, 0])
    }
}

// MARK: - Test Helpers

// MARK: State

struct PingPong {
    var ping: Count = .init()
    var pong: Count = .init()
}

extension PingPong: State {
    static func reducer(state: inout PingPong, action _: Action) -> PingPong {
        state
    }

    enum Action: String {
        case inaction
    }
}

struct Count {
    var count = 0
}

extension Count: State {
    enum Action {
        case initialize, increment(Int), decrement(Int)
    }

    static func reducer(state: inout Self, action: Action) -> Self {
        switch action {
        case .initialize:
            return Count()
        case let .increment(value):
            state.count += value
        case let .decrement(value):
            state.count -= value
        }
        return state
    }
}

extension Count.Action: RawRepresentable {
    typealias RawValue = String

    public init?(rawValue: RawValue) {
        let components = rawValue.components(separatedBy: ",")
        let value = components.count == 2 ? components.last.flatMap(Int.init) : nil

        if components.first == "initialize" {
            self = .initialize
        } else if components.first == "increment", let value = value {
            self = .increment(value)
        } else if components.first == "decrement", let value = value {
            self = .decrement(value)
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .initialize:
            return "initialize"
        case let .increment(value):
            return "increment,\(value)"
        case let .decrement(value):
            return "decrement,\(value)"
        }
    }
}

// MARK: SUT & Spy

private func makeSut<S: State>(initialState: S) -> Store<S> {
    Store(initialState: initialState)
}

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
