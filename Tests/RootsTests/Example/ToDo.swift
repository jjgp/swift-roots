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

func == (lhs: Filters.Status, rhs: Filters.Status) -> Bool {
    switch (lhs, rhs) {
    case (.all, .all), (.completed, .completed), (.incomplete, .incomplete):
        return true
    default:
        return false
    }
}

func == (lhs: Filters, rhs: Filters) -> Bool {
    lhs.colors == rhs.colors && lhs.status == rhs.status
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

func == (lhs: ToDo, rhs: ToDo) -> Bool {
    lhs.color == rhs.color && lhs.completed == rhs.completed && lhs.id == rhs.id && lhs.text == rhs.text
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

func == (lhs: [Int: ToDo], rhs: [Int: ToDo]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }

    for (key, value) in lhs {
        guard let todo = rhs[key], todo == value else {
            return false
        }
    }

    return true
}

func == (lhs: ToDoList, rhs: ToDoList) -> Bool {
    lhs.filters == rhs.filters && lhs.order == rhs.order && lhs.todos == rhs.todos
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
        state.order.append(toDo.id)
    case .clearFilters:
        state.filters = .init()
    case .clearToDos:
        state.todos.removeAll()
        state.order.removeAll()
    case .initialize:
        state = .init()
    case let .removeToDo(id: id):
        state.todos.removeValue(forKey: id)
        state.order.removeAll(where: {
            $0 == id
        })
    }
    return state
}
