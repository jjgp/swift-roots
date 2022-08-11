import Combine
import Roots
import RootsTest
import XCTest

class StoreTests: XCTestCase {
    func testActionsOnToDoListStore() {
        // Given a store with a non-Equatable ToDoList state
        let todoListStore = Store(initialState: ToDoList(), reducer: toDoListReducer(state:action:))
        let todoListSpy = PublisherSpy(todoListStore)

        // When sending actions
        todoListStore.send(.initialize)
        todoListStore.send(.add(toDo: .init(color: "red", completed: false, id: 0, text: "hello,")))
        todoListStore.send(.add(toDo: .init(color: "orange", completed: false, id: 1, text: " world!")))

        // Then the published states should have redundancy
        let todoListValues = todoListSpy.values
        // there should be 6 published values
        XCTAssertEqual(todoListValues.count, 4)
        // the first and second are the initial and .initialize states
        XCTAssertTrue(todoListValues[0] == todoListValues[1])
        // after adding the first ToDo
        XCTAssertTrue(todoListValues[2].order == [0])
        XCTAssertEqual(todoListValues[2].todos[0]?.color, "red")
        XCTAssertEqual(todoListValues[2].todos[0]?.completed, false)
        XCTAssertEqual(todoListValues[2].todos[0]?.id, 0)
        XCTAssertEqual(todoListValues[2].todos[0]?.text, "hello,")
        // after adding the other ToDo
        XCTAssertTrue(todoListValues[3].order == [0, 1])
        XCTAssertEqual(todoListValues[3].todos[1]?.color, "orange")
        XCTAssertEqual(todoListValues[3].todos[1]?.completed, false)
        XCTAssertEqual(todoListValues[3].todos[1]?.id, 1)
        XCTAssertEqual(todoListValues[3].todos[1]?.text, " world!")
    }

    func testToDoListStateBindingDuplicatePredicate() {
        let todoListStateBinding = StateBinding(initialState: ToDoList(), isDuplicate: ==)
        let todoListStore = Store(stateBinding: todoListStateBinding, reducer: toDoListReducer(state:action:))
        let todoListSpy = PublisherSpy(todoListStore)

        // When sending actions
        todoListStore.send(.initialize)
        todoListStore.send(.add(toDo: .init(color: "red", completed: false, id: 0, text: "hello,")))
        todoListStore.send(.add(toDo: .init(color: "orange", completed: false, id: 1, text: " world!")))

        // Then the published states should not have redundancy
        let todoListValues = todoListSpy.values
        // there should be 6 published values
        XCTAssertEqual(todoListValues.count, 3)
        // the first published value is the initial state
        XCTAssertTrue(todoListValues[0] == .init())
        // after adding the first ToDo
        XCTAssertTrue(todoListValues[1].order == [0])
        XCTAssertEqual(todoListValues[1].todos[0]?.color, "red")
        XCTAssertEqual(todoListValues[1].todos[0]?.completed, false)
        XCTAssertEqual(todoListValues[1].todos[0]?.id, 0)
        XCTAssertEqual(todoListValues[1].todos[0]?.text, "hello,")
        // after adding the other ToDo
        XCTAssertTrue(todoListValues[2].order == [0, 1])
        XCTAssertEqual(todoListValues[2].todos[1]?.color, "orange")
        XCTAssertEqual(todoListValues[2].todos[1]?.completed, false)
        XCTAssertEqual(todoListValues[2].todos[1]?.id, 1)
        XCTAssertEqual(todoListValues[2].todos[1]?.text, " world!")
    }

    func testInitializeCountStore() {
        // Given a store with a Count state
        let countStore = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        // When initializing the state (an action that is redundant)
        countStore.send(.initialize)

        // Then the state should not emit a subsequent new state (as it's a duplicate)
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0])
    }

    func testActionsOnCountStore() {
        // Given a store with a Count state
        let countStore = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        // When actions are sent to increment/decrement/initialize
        countStore.send(.increment(10))
        countStore.send(.decrement(20))
        countStore.send(.initialize)

        // Then the state values should reflect those actions
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 10, -10, 0])
    }

    func testActionsOnCountsStore() {
        // Given a store with a Counts state
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let countsSpy = PublisherSpy(countsStore)

        // When actions are sent to to add and to initialize
        countsStore.send(creator: \.addToCount, passing: \.first, 10)
        countsStore.send(creator: \.addToCount, passing: \.second, 20)
        countsStore.send(creator: \.initialize)

        // Then the state values should reflect those actions
        let countsValues = countsSpy.values.map { [$0.first.count, $0.second.count] }
        XCTAssertEqual(countsValues, [
            [0, 0],
            [10, 0],
            [10, 20],
            [0, 0],
        ])
    }

    func testCountsStoreToAnyStateContainer() {
        // Given a store with a Counts state that is converted to any StateContainer
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let countsAnyStateContainer = countsStore.toAnyStateContainer()

        // When actions are sent to to add and to initialize
        // Then the state values should reflect those actions
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)

        countsAnyStateContainer.send(creator: \.addToCount, passing: \.first, 10)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 10)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)

        countsAnyStateContainer.send(creator: \.addToCount, passing: \.second, 20)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 10)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 20)

        countsAnyStateContainer.send(creator: \.initialize)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)
    }

    func testToAnyStateContainerDoesNotRetainStore() {
        // Given a store with a Counts state that is converted to any StateContainer
        let countsAnyStateContainer = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
            .toAnyStateContainer() // The original store is not stored in local scope and deallocates

        // When actions are sent to to add and to initialize
        // Then the state values should be unaffected
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)

        countsAnyStateContainer.send(creator: \.addToCount, passing: \.first, 10)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)

        countsAnyStateContainer.send(creator: \.addToCount, passing: \.second, 20)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)

        countsAnyStateContainer.send(creator: \.initialize)
        XCTAssertEqual(countsAnyStateContainer.state.first.count, 0)
        XCTAssertEqual(countsAnyStateContainer.state.second.count, 0)
    }

    func testAllToDoListStoresInScope() {
        // Given all scoped ToDo stores
        let todoListStore = Store(initialState: ToDoList(), reducer: toDoListReducer(state:action:))
        let filtersStore = todoListStore.scope(to: \.filters, reducer: filtersReducer(state:action:))
        let todoStore = todoListStore.scope(to: \.todos, reducer: toDoReducer(state:action:))

        let todoListSpy = PublisherSpy(todoListStore)
        let filtersSpy = PublisherSpy(filtersStore)
        let todoSpy = PublisherSpy(todoStore)

        // When sending actions to the scoped store
        todoListStore.send(.add(toDo: .init(color: "red", completed: false, id: 0, text: "hello, world!")))
        filtersStore.send(.add(color: "red"))
        todoStore.send(.setColor("orange", id: 0))

        // Then each store should emit consistent state values
        let todoListValues = todoListSpy.values
        let filtersValues = filtersSpy.values
        let todoValues = todoSpy.values
        XCTAssertEqual(todoListValues.count, 4)
        XCTAssertTrue(todoListValues[0] == .init())
        XCTAssertTrue(todoListValues[1].todos == todoValues[1])
        XCTAssertTrue(todoListValues[2].filters == filtersValues[2])
        XCTAssertTrue(todoListValues[3].todos == todoValues[3])
        XCTAssertEqual(filtersValues.count, 4)
        XCTAssertTrue(filtersValues[0] == .init())
        XCTAssertTrue(filtersValues[1] == .init())
        XCTAssertTrue(filtersValues[2] == .init(colors: ["red"]))
        XCTAssertTrue(filtersValues[2] == filtersValues[3])
        XCTAssertEqual(todoValues.count, 4)
        XCTAssertTrue(todoValues[0] == .init())
        XCTAssertTrue(todoValues[1] == [0: .init(color: "red", completed: false, id: 0, text: "hello, world!")])
        XCTAssertTrue(todoValues[1] == todoValues[2])
        XCTAssertTrue(todoValues[3] == [0: .init(color: "orange", completed: false, id: 0, text: "hello, world!")])
    }

    func testAllToDoListStoresInScopeWithIsDuplicatePredicate() {
        // Given all scoped ToDo stores with a duplicate predicate
        let todoListStore = Store(
            stateBinding: .init(initialState: ToDoList(), isDuplicate: ==),
            reducer: toDoListReducer(state:action:)
        )
        let filtersStore = todoListStore.scope(to: \.filters, isDuplicate: ==, reducer: filtersReducer(state:action:))
        let todoStore = todoListStore.scope(to: \.todos, isDuplicate: ==, reducer: toDoReducer(state:action:))

        let todoListSpy = PublisherSpy(todoListStore)
        let filtersSpy = PublisherSpy(filtersStore)
        let todoSpy = PublisherSpy(todoStore)

        // When sending actions to the scoped store
        todoListStore.send(.add(toDo: .init(color: "red", completed: false, id: 0, text: "hello, world!")))
        filtersStore.send(.add(color: "red"))
        todoStore.send(.setColor("orange", id: 0))

        // Then each store should emit consistent state values
        let todoListValues = todoListSpy.values
        let filtersValues = filtersSpy.values
        let todoValues = todoSpy.values
        XCTAssertEqual(todoListValues.count, 4)
        XCTAssertTrue(todoListValues[0] == .init())
        XCTAssertTrue(todoListValues[1].todos == todoValues[1])
        XCTAssertTrue(todoListValues[2].filters == filtersValues[1])
        XCTAssertTrue(todoListValues[3].todos == todoValues[2])
        XCTAssertEqual(filtersValues.count, 2)
        XCTAssertTrue(filtersValues[0] == .init())
        XCTAssertTrue(filtersValues[1] == .init(colors: ["red"]))
        XCTAssertEqual(todoValues.count, 3)
        XCTAssertTrue(todoValues[0] == .init())
        XCTAssertTrue(todoValues[1] == [0: .init(color: "red", completed: false, id: 0, text: "hello, world!")])
        XCTAssertTrue(todoValues[2] == [0: .init(color: "orange", completed: false, id: 0, text: "hello, world!")])
    }

    func testStoreInFirstCountScope() {
        // Given a store scoped to the first Count state
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStore.scope(to: \.first, reducer: Count.reducer(state:action:))

        let countsSpy = PublisherSpy(countsStore)
        let firstCountSpy = PublisherSpy(firstCountStore)

        // When sending actions to the scoped store
        firstCountStore.send(.increment(10))
        firstCountStore.send(.decrement(20))
        firstCountStore.send(.initialize)

        // Then each store should emit consistent state values
        let countsValues = countsSpy.values.map(\.first.count)
        let firstCountValues = firstCountSpy.values.map(\.count)
        XCTAssertEqual(countsValues, [0, 10, -10, 0])
        XCTAssertEqual(firstCountValues, [0, 10, -10, 0])
    }

    func testAllCountsStoresInScope() {
        // Given a all Count(s) stores
        let countsStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let firstCountStore = countsStore.scope(to: \.first, reducer: Count.reducer(state:action:))
        let secondCountStore = countsStore.scope(to: \.second, reducer: Count.reducer(state:action:))

        let countsSpy = PublisherSpy(countsStore)
        let firstCountSpy = PublisherSpy(firstCountStore)
        let secondCountSpy = PublisherSpy(secondCountStore)

        // When sending actions to all stores
        firstCountStore.send(.increment(10))
        countsStore.send(creator: \.addToCount, passing: \.first, -20)
        secondCountStore.send(.decrement(20))
        countsStore.send(creator: \.addToCount, passing: \.second, 40)
        firstCountStore.send(.initialize)
        secondCountStore.send(.initialize)

        // Then each store should emit consistent state values
        let countsValues = countsSpy.values.map { [$0.first.count, $0.second.count] }
        let firstCountValues = firstCountSpy.values.map(\.count)
        let secondCountValues = secondCountSpy.values.map(\.count)
        XCTAssertEqual(countsValues, [
            [0, 0],
            [10, 0],
            [-10, 0],
            [-10, -20],
            [-10, 20],
            [0, 20],
            [0, 0],
        ])
        XCTAssertEqual(firstCountValues, [0, 10, -10, 0])
        XCTAssertEqual(secondCountValues, [0, -20, 20, 0])
    }

    func testSendingFromASubscriptionBuffersRecursiveActions() {
        /*
         This test ensures that recursive actions are buffered until the store is done sending. Without the buffer,
         the test fails intermittently due to the rescheduling on the main queue from recursively publishing state
         updates.
         */

        // Given a count store that recursively decrements in a subscriber
        let countStore = Store(initialState: Count(), reducer: Count.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        let sub = countStore.sink { [weak countStore] state in
            if state.count == 10 {
                countStore?.send(.decrement(10))
            }
        }

        // When sending actions to increment
        countStore.send(.increment(10))
        countStore.send(.increment(10))

        // Then the decrements should be interleaved correctly despite the recursive send
        let countValues = countSpy.values.map(\.count)
        XCTAssertEqual(countValues, [0, 10, 0, 10, 0])
        sub.cancel()
    }

    func testRecursiveActionsFromStoresInScope() {
        let sendSchedulerSpy = SendSchedulerSpy()
        let countsStore = Store(
            sendScheduler: sendSchedulerSpy,
            initialState: Counts(),
            reducer: Counts.reducer(state:action:)
        )
        let firstCountStore = countsStore.scope(to: \.first, reducer: Count.reducer(state:action:))
        let secondCountStore = countsStore.scope(to: \.second, reducer: Count.reducer(state:action:))

        var cancellables = Set<AnyCancellable>()

        countsStore
            .sink { [weak countsStore] state in
                if state.first.count == 10 {
                    countsStore?.send(creator: \.addToCount, passing: \.first, -10)
                }

                if state.second.count == 10 {
                    countsStore?.send(creator: \.addToCount, passing: \.second, -10)
                }
            }
            .store(in: &cancellables)

        firstCountStore
            .sink { [weak firstCountStore] state in
                if state.count == 10 {
                    firstCountStore?.send(.decrement(10))
                }
            }
            .store(in: &cancellables)

        secondCountStore
            .sink { [weak secondCountStore] state in
                if state.count == 10 {
                    secondCountStore?.send(.decrement(10))
                }
            }
            .store(in: &cancellables)

        firstCountStore.send(.increment(10))
        XCTAssertEqual(sendSchedulerSpy.sendNext(), Count.Action.increment(10))
        XCTAssertEqual(sendSchedulerSpy.sendPendingBuffer.count, 2)
        for _ in 0 ..< sendSchedulerSpy.sendPendingBuffer.count {
            let sent: Any? = sendSchedulerSpy.sendNext()
            if let sent = sent as? Count.Action {
                XCTAssertEqual(sent, .decrement(10))
            } else if let sent = sent as? Counts.Addition {
                XCTAssertEqual(sent.keyPath, \.first)
                XCTAssertEqual(sent.value, -10)
            } else {
                XCTFail("unexpected action sent")
            }
        }
        XCTAssertEqual(sendSchedulerSpy.sendPendingBuffer.count, 0)

        secondCountStore.send(.increment(10))
        XCTAssertEqual(sendSchedulerSpy.sendNext(), Count.Action.increment(10))
        XCTAssertEqual(sendSchedulerSpy.sendPendingBuffer.count, 2)
        for _ in 0 ..< sendSchedulerSpy.sendPendingBuffer.count {
            let sent: Any? = sendSchedulerSpy.sendNext()
            if let sent = sent as? Count.Action {
                XCTAssertEqual(sent, .decrement(10))
            } else if let sent = sent as? Counts.Addition {
                XCTAssertEqual(sent.keyPath, \.second)
                XCTAssertEqual(sent.value, -10)
            } else {
                XCTFail("unexpected action sent")
            }
        }
        XCTAssertEqual(sendSchedulerSpy.sendPendingBuffer.count, 0)
    }
}
