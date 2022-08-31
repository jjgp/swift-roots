import Foundation

class CurrentValueSubject<Value>: Subject {
    private var currentValue: Value
    private let lock: UnfairLock = .init()
    var value: Value {
        get {
            lock {
                currentValue
            }
        }
        set {
            send(newValue)
        }
    }

    private var subscriptions: Set<Subscription<Value>> = []

    init(_ value: Value) {
        currentValue = value
    }
}

extension CurrentValueSubject {
    func send(_ value: Value) {
        send { currentValue in
            currentValue = value
        }
    }

    func send(mutateValue: (inout Value) -> Void) {
        let subscriptions = lock {
            mutateValue(&currentValue)
            return self.subscriptions
        }

        subscriptions.forEach { subscription in
            subscription.send(value)
        }
    }

    func subscribe(receiveValue: @escaping (Value) -> Void) -> Cancellable {
        let subscription = Subscription(receiveValue: receiveValue)

        let value = lock {
            subscriptions.insert(subscription)
            return currentValue
        }

        subscription.send(value)

        return Cancellable {
            self.lock {
                self.subscriptions.remove(subscription)
            }
        }
    }
}

private extension CurrentValueSubject {
    final class Subscription<Value>: Hashable {
        let receive: (Value) -> Void

        init(receiveValue: @escaping (Value) -> Void) {
            receive = receiveValue
        }

        static func == (lhs: Subscription<Value>, rhs: Subscription<Value>) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }

        func send(_ value: Value) {
            receive(value)
        }
    }
}
