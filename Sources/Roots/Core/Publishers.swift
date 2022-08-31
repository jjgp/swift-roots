public enum Publishers {}

public extension Publishers {
    final class Filter<Upstream: Publisher>: Publisher {
        let isIncluded: (Output) -> Bool
        let upstream: Upstream

        public init(_ upstream: Upstream, isIncluded: @escaping (Output) -> Bool) {
            self.isIncluded = isIncluded
            self.upstream = upstream
        }

        public typealias Output = Upstream.Output
    }
}

public extension Publishers.Filter {
    func subscribe(receiveValue: @escaping (Output) -> Void) -> Cancellable {
        upstream.subscribe { value in
            if self.isIncluded(value) {
                receiveValue(value)
            }
        }
    }
}

public extension Publisher {
    func filter(isIncluded: @escaping (Output) -> Bool) -> Publishers.Filter<Self> {
        .init(self, isIncluded: isIncluded)
    }
}

public extension Publisher where Output: Equatable {
    func removeDuplicates() -> Publishers.Filter<Self> {
        var currentValue: Output?
        return .init(self) { nextValue in
            defer {
                currentValue = nextValue
            }
            return currentValue != nextValue
        }
    }
}
