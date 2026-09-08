import Checkpoint_Test_Support
import Cursor
import Testing

extension Cursor {
    @Suite
    struct `Standard library cursors restore snapshots` {}
}

extension Cursor.`Standard library cursors restore snapshots` {

    @Test
    func `A slice iterates its elements in order`() {
        var cursor = [1, 2, 3][...]

        #expect(cursor.next() == 1)
        #expect(cursor.next() == 2)
        #expect(cursor.next() == 3)
        #expect(cursor.next() == nil)
    }

    @Test
    func `A slice checkpoint replays the sequence`() {
        var cursor = [1, 2, 3][...]
        _ = cursor.next()

        let mark = cursor.checkpoint
        #expect(cursor.next() == 2)
        cursor.seek(to: mark)
        #expect(cursor.next() == 2)
    }

    @Test
    func `A slice satisfies the restoration laws`() {
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
    func `A substring is a character cursor`() {
        var cursor: Substring = "ab"
        let mark = cursor.checkpoint

        #expect(cursor.next() == "a")
        #expect(cursor.next() == "b")
        #expect(cursor.next() == nil)

        cursor.seek(to: mark)
        #expect(cursor == "ab")
    }
}

extension Cursor.`Standard library cursors restore snapshots` {
    @Test
    func `Nested slice checkpoints restore nonzero bounds after exhaustion`() {
        var cursor = [0, 1, 2, 3, 4][1..<4]
        let first = cursor.checkpoint
        #expect(cursor.next() == 1)
        let second = cursor.checkpoint
        #expect(cursor.next() == 2)
        #expect(cursor.next() == 3)
        let end = cursor.checkpoint
        #expect(cursor.next() == nil)
        #expect(cursor.next() == nil)

        cursor.seek(to: second)
        #expect(cursor.startIndex == 2)
        #expect(cursor.endIndex == 4)
        #expect(cursor.next() == 2)
        cursor.seek(to: first)
        #expect(cursor.startIndex == 1)
        #expect(cursor.next() == 1)
        cursor.seek(to: end)
        #expect(cursor.startIndex == 4)
        #expect(cursor.next() == nil)
    }

    @Test
    func `A slice checkpoint restores contents independently of later copies`() {
        var cursor = [0, 1, 2, 3][1..<4]
        let mark = cursor.checkpoint
        var copy = cursor
        cursor[2] = 8
        copy[1] = 9
        #expect(Array(cursor) == [1, 8, 3])
        #expect(Array(copy) == [9, 2, 3])
        #expect(Array(mark) == [1, 2, 3])

        cursor = [7][...]
        cursor.seek(to: mark)
        #expect(cursor.startIndex == 1)
        #expect(cursor.endIndex == 4)
        #expect(Array(cursor) == [1, 2, 3])
        #expect(Array(copy) == [9, 2, 3])
    }

    @Test
    func `Equal slice checkpoint contents can have different bounds`() {
        let repeated = [1, 2, 1, 2]
        let first = repeated[0..<2].checkpoint
        let second = repeated[2..<4].checkpoint

        #expect(first.startIndex != second.startIndex)
        #expect(first == second)
        #expect(first == [1, 2][...].checkpoint)
    }

    @Test
    func `An unchanged NaN slice checkpoint compares equal and restores its elements`() {
        var cursor = [Double.nan, 1][...]
        let mark = cursor.checkpoint

        #expect(cursor.checkpoint == mark)
        #expect(cursor.next()?.isNaN == true)
        #expect(cursor.checkpoint != mark)
        #expect(cursor.next() == 1)
        #expect(cursor.next() == nil)
        cursor.seek(to: mark)
        #expect(cursor.checkpoint == mark)
        #expect(cursor.next()?.isNaN == true)
    }

    @Test
    func `Substring checkpoints replay complete Unicode characters`() {
        let expected: [Character] = ["é", "e\u{301}", "👩‍👩‍👧‍👦", "🇳🇱", "\r\n"]
        var cursor = Substring(String(expected))
        let first = cursor.checkpoint
        #expect(cursor.next() == expected[0])
        let second = cursor.checkpoint
        for character in expected.dropFirst() {
            #expect(cursor.next() == character)
        }
        let end = cursor.checkpoint
        #expect(cursor.next() == nil)
        #expect(cursor.next() == nil)

        cursor.seek(to: second)
        #expect(cursor.startIndex == second.startIndex)
        #expect(cursor.next() == expected[1])
        cursor.seek(to: first)
        #expect(Array(cursor) == expected)
        cursor.seek(to: end)
        #expect(cursor.next() == nil)
    }

    @Test
    func `Substring checkpoint equality preserves canonical character equivalence`() {
        let composed: Substring = "é"
        let decomposed: Substring = "e\u{301}"

        #expect(Array(composed.utf8) != Array(decomposed.utf8))
        #expect(composed.checkpoint == decomposed.checkpoint)
    }
}
