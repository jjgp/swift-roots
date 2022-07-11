public protocol Saga {
    associatedtype S: State

    @discardableResult
    func take(_ action: Action) async -> Action
    func take<T: Saga>(every action: Action, and run: T) where T.S == S
    func put(_ action: Action)
    func run() async
    func run(on action: Action) async

    typealias Action = S.Action
}

extension Saga {
    func run() async {
        await take(.init(rawValue: "foobar")!)
        put(.init(rawValue: "barbaz")!)
    }
}
