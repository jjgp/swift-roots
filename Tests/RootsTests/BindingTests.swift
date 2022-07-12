import Roots
import XCTest

// TODO: convert to Publisher
struct Binding<S: State> {
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

extension Binding {
    init(wrappedState: S) {
        var wrappedState = wrappedState
        self.init(getState: { wrappedState }, setState: { wrappedState = $0 })
    }
}

extension Binding {
    func map<ChildS: State>(_ keyPath: WritableKeyPath<S, ChildS>) -> Binding<ChildS> {
        Binding<ChildS>(
            getState: { wrappedState[keyPath: keyPath] },
            setState: { wrappedState[keyPath: keyPath] = $0 }
        )
    }
}

class BindingTests: XCTestCase {
    func testWrappedState() {
        var count = Count()
        let binding = Binding(wrappedState: count)
        count.count += 1
        binding.wrappedState = count

        XCTAssertEqual(count, binding.wrappedState)
    }

    func testMappedBinding() {
        let pingPong = PingPong()
        let pingPongBinding = Binding(wrappedState: pingPong)
        let pingBinding = pingPongBinding.map(\.ping)
        pingBinding.wrappedState = Count(count: 42)

        XCTAssertEqual(pingPongBinding.wrappedState.ping, pingBinding.wrappedState)
    }
}
