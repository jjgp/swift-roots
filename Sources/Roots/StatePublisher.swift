import Combine

protocol StatePublisher: ObservableObject {
    associatedtype S: State

    var cancellables: Set<AnyCancellable> { get }
    var state: S? { get }
    var statePublished: Published<S?> { get }
    var statePublisher: Published<S?>.Publisher { get }
}
