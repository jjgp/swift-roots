import Roots

// MARK: - Count

struct Count: Equatable {
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

// MARK: - Counts

struct Counts: Equatable {
    var first: Count = .init()
    var second: Count = .init()
}

extension Counts {
    struct Initialize: Action {}

    struct Addition: Action {
        let keyPath: WritableKeyPath<Counts, Count>
        let value: Int

        init(to keyPath: WritableKeyPath<Counts, Count>, by value: Int) {
            self.keyPath = keyPath
            self.value = value
        }
    }
}

extension Counts {
    var initialize: Action {
        Initialize()
    }

    var addToCount: (WritableKeyPath<Counts, Count>, Int) -> Action {
        Addition.init(to:by:)
    }
}

extension Counts {
    static func reducer(state: inout Counts, action: Action) -> Counts {
        switch action {
        case _ as Initialize:
            return Counts()
        case let action as Addition:
            state[keyPath: action.keyPath].count += action.value
        default:
            break
        }

        return state
    }
}
