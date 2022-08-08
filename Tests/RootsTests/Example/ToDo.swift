/*
 Borrowed from:
 https://redux.js.org/tutorials/fundamentals/part-3-state-actions-reducers
 */

// MARK: - Filters

struct Filters {
    enum Status {
        case all, completed, incomplete
    }

    var colors: Set<String> = []
    var status: Status = .all
}

enum FiltersActions {
    case add(color: String)
    case clearColors
    case remove(color: String)
    case update(status: Filters.Status)
}

func filtersReducer(state: inout Filters, action: FiltersActions) -> Filters {
    switch action {
    case let .add(color: color):
        state.colors.insert(color)
    case .clearColors:
        state.colors.removeAll()
    case let .remove(color: color):
        state.colors.remove(color)
    case let .update(status: status):
        state.status = status
    }
    return state
}

// MARK: - ToDo

struct ToDo {
    var color: String
    var completed: Bool
    let id: Int
    var text: String
}

enum ToDoActions {
    case setColor(String, id: Int)
    case setCompleted(Bool, id: Int)
    case setText(String, id: Int)
}

func toDoReducer(state: inout [Int: ToDo], action: ToDoActions) -> [Int: ToDo] {
    switch action {
    case let .setColor(color, id: id):
        state[id]?.color = color
    case let .setCompleted(completed, id: id):
        state[id]?.completed = completed
    case let .setText(text, id: id):
        state[id]?.text = text
    }
    return state
}

// MARK: - ToDoList

struct ToDoList {
    var filters: Filters = .init()
    var order: [Int] = []
    var todos: [Int: ToDo] = [:]
}

enum ToDoListActions {
    case add(toDo: ToDo)
    case clearFilters
    case clearToDos
    case initialize
    case removeToDo(id: Int)
}

func toDoListReducer(state: inout ToDoList, action: ToDoListActions) -> ToDoList {
    switch action {
    case let .add(toDo: toDo):
        state.todos[toDo.id] = toDo
    case .clearFilters:
        state.filters = .init()
    case .clearToDos:
        state.todos.removeAll()
    case .initialize:
        state = .init()
    case let .removeToDo(id: id):
        state.todos.removeValue(forKey: id)
    }
    return state
}
