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

    struct Increment: Action {
        let keyPath: WritableKeyPath<PingPong, Count>
        let value: Int
    }
}

extension PingPong {
    var initialize: Action {
        PingPong.Initialize()
    }

    var incrementPing: (Int) -> Action {
        { value in
            PingPong.Increment(keyPath: \.ping, value: value)
        }
    }

    var incrementPong: (Int) -> Action {
        { value in
            PingPong.Increment(keyPath: \.pong, value: value)
        }
    }
}

extension PingPong {
    static func reducer(state: inout PingPong, action: Action) -> PingPong {
        if action is PingPong.Initialize {
            return PingPong()
        } else if let action = action as? PingPong.Increment {
            state[keyPath: action.keyPath].count += action.value
        }

        return state
    }
}
