import Combine
@testable import Roots
import XCTest

class BridgedPublisherTests: XCTestCase {}

// MARK: - CurrentValueSubject

extension BridgedPublisherTests {
    func xtestBridgedCurrentValueSubject() {
        let subject = CurrentValueSubject(0)
        let bridgedPublisher = subject.asBridged

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
}
