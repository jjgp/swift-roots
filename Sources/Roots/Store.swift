public final class Store<State>: Publisher, StateContainer {
    private var dispatch: Dispatch!
    private let dispatcher: Dispatcher
    private var subject: BindingValueSubject<State>

    private init(
        dispatcher: Dispatcher,
        middleware: Middleware<State>?,
        mutation: @escaping Mutation<State>,
        subject: BindingValueSubject<State>
    ) {
        self.dispatcher = dispatcher
        self.subject = subject

        let dispatch: Dispatch = { action in
            subject.send { state in
                mutation(&state, action)
            }
        }

        if let middleware = middleware {
            middleware.store = eraseToAnyStateContainer()
            self.dispatch = { action in
                middleware.respond(to: action, forwardingTo: dispatch)
            }
        } else {
            self.dispatch = dispatch
        }
    }
}

public extension Store {
    convenience init(
        dispatcher: Dispatcher = CombinedDispatcher(OnQueueDispatcher(), BarrierDispatcher()),
        state: State,
        middleware: Middleware<State>? = nil,
        mutation: @escaping Mutation<State>
    ) {
        self.init(
            dispatcher: dispatcher,
            middleware: middleware,
            mutation: mutation,
            subject: BindingValueSubject(state)
        )
    }
}

public extension Store {
    func subscribe(receiveValue: @escaping (State) -> Void) -> Cancellable {
        subject.subscribe(receiveValue: receiveValue)
    }
}

public extension Store {
    func scope<T>(
        state keyPath: WritableKeyPath<State, T>,
        middleware: Middleware<T>? = nil,
        mutation: @escaping Mutation<T>
    ) -> Store<T> {
        .init(
            dispatcher: dispatcher,
            middleware: middleware,
            mutation: mutation,
            subject: subject.scope(value: keyPath)
        )
    }
}

public extension Store {
    var state: State {
        subject.wrappedValue
    }

    func send(_ action: Action) {
        dispatcher.receive(action: action, transmitTo: dispatch)
    }

    func eraseToAnyStateContainer() -> AnyStateContainer<State> {
        AnyStateContainer(
            getState: { [weak self] in
                guard let self = self else {
                    fatalError("Store has already deallocated before call to getState")
                }

                return self.state
            },
            send: { [weak self] action in
                guard let self = self else {
                    fatalError("Store has already deallocated before call to send(_:)")
                }

                self.send(action)
            }
        )
    }
}
