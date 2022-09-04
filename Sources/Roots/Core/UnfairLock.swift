import Foundation

final class UnfairLock {
    private let underlyingLock: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        underlyingLock = .allocate(capacity: 1)
        underlyingLock.initialize(to: os_unfair_lock())
    }

    deinit {
        underlyingLock.deinitialize(count: 1)
        underlyingLock.deallocate()
    }
}

extension UnfairLock {
//    @inlinable
    func callAsFunction(block: () -> Void) {
        os_unfair_lock_lock(underlyingLock)
        block()
        os_unfair_lock_unlock(underlyingLock)
    }

//    @inlinable
    func callAsFunction<T>(block: () -> T) -> T {
        os_unfair_lock_lock(underlyingLock)
        defer {
            os_unfair_lock_unlock(underlyingLock)
        }

        return block()
    }

//    @inlinable
    func lock() {
        os_unfair_lock_lock(underlyingLock)
    }

//    @inlinable
    func unlock() {
        os_unfair_lock_unlock(underlyingLock)
    }
}
