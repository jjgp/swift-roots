// import Foundation
//
// public extension Middleware {
//    static func assertDispatch(on queue: DispatchQueue) -> Self {
//        .init { _, next in
//            { action in
//                dispatchPrecondition(condition: .onQueue(queue))
//                next(action)
//            }
//        }
//    }
// }
