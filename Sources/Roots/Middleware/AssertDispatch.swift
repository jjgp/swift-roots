import Foundation

public func assertDispatch<State, Action>(on queue: DispatchQueue) -> Middleware<State, Action> {
    .assertDispatch(on: queue)
}

public extension Middleware {
    static func assertDispatch(on queue: DispatchQueue) -> Self {
        .init { _ in
            { next in
                { action in
                    dispatchPrecondition(condition: .onQueue(queue))
                    next(action)
                }
            }
        }
    }
}
