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

protocol PingPongAction {}

extension PingPong {
    struct Initialize: PingPongAction {}

    struct Increment: PingPongAction {
        let keyPath: WritableKeyPath<PingPong, Count>
        let value: Int
    }
}

extension PingPong {
    static var initialize: Initialize {
        .init()
    }

    static func ping(_ value: Int) -> Increment {
        .init(keyPath: \.ping, value: value)
    }

    static func pong(_ value: Int) -> Increment {
        .init(keyPath: \.pong, value: value)
    }
}

extension PingPong {
    static func reducer(state: inout PingPong, action: PingPongAction) -> PingPong {
        if action is PingPong.Initialize {
            return PingPong()
        } else if let action = action as? PingPong.Increment {
            state[keyPath: action.keyPath].count += action.value
        }

        return state
    }
}
