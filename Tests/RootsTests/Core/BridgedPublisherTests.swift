import Combine
@testable import Roots
import XCTest

class BridgedPublisherTests: XCTestCase {}

// MARK: - CurrentValueSubject

extension BridgedPublisherTests {
    func xtestBridgedCurrentValueSubject() {
        let subject = CurrentValueSubject(0)
        let bridgedPublisher = subject.bridged()

        let sub = bridgedPublisher
            .removeDuplicates()
            .sink {
                print($0)
                subject.send(20)
            }

        subject.send(10)
        subject.send(10)

        sub.cancel()

        subject.send(0)
        subject.send(10)
    }

    func xtestRecursion() {
        let subject = CurrentValueSubject(0)

        let sub = subject
            .removeDuplicates()
            .subscribe {
                print($0)
                subject.send(20)
            }

        subject.send(10)
        subject.send(10)

        sub.cancel()

        subject.send(0)
        subject.send(10)
    }

    func xtestCombine() {
        let subject = Combine.CurrentValueSubject<Int, Never>(10)

        let sub = subject
            .sink {
                print($0)
                subject.send(20)
            }

        subject.send(10)
        subject.send(10)

        sub.cancel()

        subject.send(0)
        subject.send(10)
    }

    func testCustomSubscriber() {
        let subject = Combine.CurrentValueSubject<Int, Never>(0)
        let spy = Spy(subject)

        subject.send(10)
    }
}

class Spy<Input>: Subscriber {
    let subject: Combine.CurrentValueSubject<Input, Never>
    var subscription: Subscription!

    public init(_ subject: Combine.CurrentValueSubject<Input, Never>) {
        self.subject = subject
        subject.subscribe(self)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        print(input)
//        subject.send(input)
        return .none
    }

    func receive(completion _: Subscribers.Completion<Never>) {
        print("completed")
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    typealias Failure = Never
}
