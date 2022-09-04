struct Binding<Value> {
    private let getValue: () -> Value
    private let setValue: (Value) -> Void
    var wrappedValue: Value {
        get {
            getValue()
        }
        nonmutating set {
            setValue(newValue)
        }
    }

    init(getValue: @escaping () -> Value, setValue: @escaping (Value) -> Void) {
        self.getValue = getValue
        self.setValue = setValue
    }
}

extension Binding {
    func scope<T>(value keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        .init {
            wrappedValue[keyPath: keyPath]
        } setValue: { value in
            wrappedValue[keyPath: keyPath] = value
        }
    }
}
