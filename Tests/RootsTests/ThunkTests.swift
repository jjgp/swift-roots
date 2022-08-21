import Roots
import RootsTest
import XCTest

class ThunkTests: XCTestCase {
    func testRunningOfAsyncThunk() async {
        let countStore = Store(initialState: Counts(), reducer: Counts.reducer(state:action:))
        let countSpy = PublisherSpy(countStore)

        await countStore.run { dispatch, _ in
            try? await Task.sleep(nanoseconds: 100_000_000)
            dispatch(Counts.Addition(to: \.first, by: 100))
        }

        let values = countSpy.values.map(\.first.count)
        XCTAssertEqual(values, [0, 100])
    }
}
