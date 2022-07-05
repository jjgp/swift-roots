import Roots

// MARK: PingPong

struct PingPong {
    var ping: Count = .init()
    var pong: Count = .init()
}

extension PingPong: State {
    static func reducer(state _: inout PingPong, action: Action) -> PingPong {
        switch action {
        case .initialize:
            return PingPong()
        }
    }

    enum Action: String {
        case initialize
    }
}

// MARK: Count

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
