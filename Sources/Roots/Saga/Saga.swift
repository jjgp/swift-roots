public protocol Saga {
    associatedtype S: State
    associatedtype A: Action

    @discardableResult
    func take(_ action: A) async -> A
    func take<T: Saga>(every action: A, and run: T) where T.S == S
    func put(_ action: A)
    func run() async
    func run(on action: A) async
}

extension Saga {
    func run() async {}
}
