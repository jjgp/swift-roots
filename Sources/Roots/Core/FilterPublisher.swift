public struct FilterPublisher<Upstream: Publisher>: Publisher {
    let isIncluded: (Output) -> Bool
    let upstream: Upstream

    public init(_ upstream: Upstream, isIncluded: @escaping (Output) -> Bool) {
        self.isIncluded = isIncluded
        self.upstream = upstream
    }

    public typealias Output = Upstream.Output
}

public extension FilterPublisher {
    func subscribe(receiveValue: @escaping (Output) -> Void) -> Cancellable {
        upstream.subscribe { value in
            if self.isIncluded(value) {
                receiveValue(value)
            }
        }
    }
}

public extension Publisher where Output: Equatable {
    func removeDuplicates() -> FilterPublisher<Self> {
        var currentValue: Output?
        return .init(self) { nextValue in
            defer {
                currentValue = nextValue
            }
            return currentValue != nextValue
        }
    }
}

public extension Publisher {
    func filter(isIncluded: @escaping (Output) -> Bool) -> FilterPublisher<Self> {
        .init(self, isIncluded: isIncluded)
    }
}
