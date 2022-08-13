import Roots
import RootsTest
import XCTest

class RunThunkTests: XCTestCase {
    func testRunningOfAsyncThunk() {
        let countStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:), middleware: RunThunk())
        let countSpy = PublisherSpy(countStore)

        let expectation = expectation(description: "the dispatch is sent")
        countStore.send(Thunk<Counts, Action> { dispatch, _ in
            await MainActor.run {
                dispatch(Counts.Addition(to: \.first, by: 100))
                expectation.fulfill()
            }
        })

        wait(for: [expectation], timeout: 1)
        let values = countSpy.values.map(\.first.count)
        XCTAssertEqual(values, [0, 100])
    }
}
