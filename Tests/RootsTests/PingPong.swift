import Roots

// MARK: Count

struct Count: State {
    var count = 0
}

extension Count {
    enum Action: Roots.Action {
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
    struct Action: Roots.Action {
        let kind: Kind
        let value: Int

        init(kind: Kind, value: Int = 0) {
            self.kind = kind
            self.value = value
        }

        enum Kind: String {
            case initialize, ping, pong
        }
    }
}

extension PingPong.Action {
    static var initialize: Self {
        .init(kind: .initialize)
    }

    static func ping(value: Int) -> Self {
        .init(kind: .ping, value: value)
    }

    static func pong(value: Int) -> Self {
        .init(kind: .pong, value: value)
    }
}

extension PingPong {
    static func reducer(state: inout PingPong, action: Action) -> PingPong {
        switch action.kind {
        case .initialize:
            return PingPong()
        case .ping:
            state.ping.count += action.value
        case .pong:
            state.pong.count += action.value
        }
        return state
    }
}
