struct BindingValueSubject<Value>: Subject {
    private let binding: Binding<Value>
    private let sendValue: (Value) -> Void
    private let sendMutateValue: (@escaping (inout Value) -> Void) -> Void
    private let subscribeReceiveValue: (@escaping (Value) -> Void) -> Cancellable
    var wrappedValue: Value {
        get {
            binding.wrappedValue
        }
        nonmutating set {
            binding.wrappedValue = newValue
        }
    }

    private init(
        binding: Binding<Value>,
        sendValue: @escaping (Value) -> Void,
        sendMutateValue: @escaping (@escaping (inout Value) -> Void) -> Void,
        subscribeReceiveValue: @escaping (@escaping (Value) -> Void) -> Cancellable
    ) {
        self.binding = binding
        self.sendValue = sendValue
        self.sendMutateValue = sendMutateValue
        self.subscribeReceiveValue = subscribeReceiveValue
    }
}

extension BindingValueSubject {
    init(_ value: Value) {
        let subject = CurrentValueSubject(value)
        let binding = Binding {
            subject.value
        } setValue: { value in
            subject.send(value)
        }

        self.init(
            binding: binding,
            sendValue: subject.send(_:),
            sendMutateValue: subject.send(mutateValue:),
            subscribeReceiveValue: subject.subscribe(receiveValue:)
        )
    }
}

extension BindingValueSubject {
    func send(_ value: Value) {
        sendValue(value)
    }

    func send(mutateValue: @escaping (inout Value) -> Void) {
        sendMutateValue(mutateValue)
    }

    func subscribe(receiveValue: @escaping (Value) -> Void) -> Cancellable {
        subscribeReceiveValue(receiveValue)
    }
}

extension BindingValueSubject {
    func scope<T>(value keyPath: WritableKeyPath<Value, T>) -> BindingValueSubject<T> {
        .init(binding: binding.scope(value: keyPath)) { value in
            sendMutateValue { (root: inout Value) in
                root[keyPath: keyPath] = value
            }
        } sendMutateValue: { mutateValue in
            sendMutateValue { (root: inout Value) in
                mutateValue(&root[keyPath: keyPath])
            }
        } subscribeReceiveValue: { receiveValue in
            subscribeReceiveValue { (root: Value) in
                receiveValue(root[keyPath: keyPath])
            }
        }
    }
}
