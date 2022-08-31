public protocol Publisher {
    associatedtype Output

    func subscribe(receiveValue: @escaping (Output) -> Void) -> Cancellable
}
