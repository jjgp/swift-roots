import Roots

// MARK: Count

struct Count: State {
    var count = 0
}

extension Count {
    enum Action: Equatable {
        case initialize, increment(Int), decrement(Int)
    }
}

extension Count {
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

// MARK: PingPong

struct PingPong: State {
    var ping: Count = .init()
    var pong: Count = .init()
}

extension PingPong {
    struct Initialize: Action {}

    struct Addition: Action {
        let keyPath: WritableKeyPath<PingPong, Count>
        let value: Int
    }
}

extension PingPong {
    var initialize: Action {
        Initialize()
    }

    var addTo: (WritableKeyPath<PingPong, Count>, Int) -> Action {
        Addition.init(keyPath:value:)
    }
}

extension PingPong {
    static func reducer(state: inout PingPong, action: Action) -> PingPong {
        switch action {
        case _ as Initialize:
            return PingPong()
        case let action as Addition:
            state[keyPath: action.keyPath].count += action.value
        default:
            break
        }

        return state
    }
}
