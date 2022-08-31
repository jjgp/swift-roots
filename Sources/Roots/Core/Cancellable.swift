public final class Cancellable: Hashable {
    private(set) var execute: Cancel?

    public init(_ cancel: @escaping Cancel) {
        execute = cancel
    }

    deinit {
        execute?()
    }

    public typealias Cancel = () -> Void
}

public extension Cancellable {
    func cancel() {
        execute?()
        execute = nil
    }
}

public extension Cancellable {
    static func == (lhs: Cancellable, rhs: Cancellable) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
