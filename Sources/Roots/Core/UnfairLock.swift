import Foundation

final class UnfairLock {
    private let lock: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }
}

extension UnfairLock {
    func callAsFunction(execute: () -> Void) {
        os_unfair_lock_lock(lock)
        execute()
        os_unfair_lock_unlock(lock)
    }

    func callAsFunction<T>(execute: () -> T) -> T {
        os_unfair_lock_lock(lock)
        defer {
            os_unfair_lock_unlock(lock)
        }

        return execute()
    }
}
