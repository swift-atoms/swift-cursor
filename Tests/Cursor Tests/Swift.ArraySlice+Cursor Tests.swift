import Checkpoint_Test_Support
import Cursor
import Cursor_Standard_Library_Integration
import Testing

@Suite
struct `Swift.ArraySlice+Cursor Tests` {

    @Test
    func `a slice iterates its elements in order`() {
        var cursor = [1, 2, 3][...]

        #expect(cursor.next() == 1)
        #expect(cursor.next() == 2)
        #expect(cursor.next() == 3)
        #expect(cursor.next() == nil)
    }

    @Test
    func `a slice checkpoint replays the sequence`() {
        var cursor = [1, 2, 3][...]
        _ = cursor.next()

        let mark = cursor.checkpoint
        #expect(cursor.next() == 2)
        cursor.seek(to: mark)
        #expect(cursor.next() == 2)
    }

    @Test
    func `a slice satisfies the Restorable laws`() {
        var cursor = [1, 2, 3][...]
        _ = cursor.next()

        #expect(RestorableLaws.seekToCurrentIsIdentity(&cursor) { $0.startIndex })
        #expect(
            RestorableLaws.checkpointRestoresAcrossMutation(
                &cursor,
                mutate: { _ = $0.next() },
                observe: { $0.startIndex }
            )
        )
    }

    @Test
    func `a substring is a character cursor`() {
        var cursor: Substring = "ab"
        let mark = cursor.checkpoint

        #expect(cursor.next() == "a")
        #expect(cursor.next() == "b")
        #expect(cursor.next() == nil)

        cursor.seek(to: mark)
        #expect(cursor == "ab")
    }
}
