import Checkpoint_Test_Support
import Cursor
import Testing

extension Cursor {
    @Suite
    struct `Cursors restore iteration state` {}
}

extension Cursor.`Cursors restore iteration state` {

    @Test
    func `A cursor iterates its elements in order`() {
        var cursor = Self.ArrayCursor([1, 2, 3])

        #expect(cursor.next() == 1)
        #expect(cursor.next() == 2)
        #expect(cursor.next() == 3)
        #expect(cursor.next() == nil)
    }

    @Test
    func `A checkpoint replays the sequence`() {
        var cursor = Self.ArrayCursor([1, 2, 3])
        _ = cursor.next()

        let mark = cursor.checkpoint
        #expect(cursor.next() == 2)
        #expect(cursor.next() == 3)

        cursor.seek(to: mark)
        #expect(cursor.next() == 2)
    }

    @Test
    func `A cursor satisfies the restoration laws`() {
        var cursor = Self.ArrayCursor([1, 2, 3])
        _ = cursor.next()

        #expect(
            RestorableLaws.seekToCurrentIsIdentity(&cursor) { $0.position }
        )
        #expect(
            RestorableLaws.checkpointRestoresAcrossMutation(
                &cursor,
                mutate: { _ = $0.next() },
                observe: { $0.position }
            )
        )
    }
}

extension Cursor.`Cursors restore iteration state` {
    private struct ArrayCursor: Cursor.`Protocol` {

        let elements: [Int]

        private(set) var position: Int

        init(_ elements: [Int]) {
            self.elements = elements
            self.position = 0
        }

        typealias Element = Int
        typealias Failure = Never

        mutating func next() -> Int? {
            guard position < elements.count else { return nil }
            defer { position += 1 }
            return elements[position]
        }

        var checkpoint: Int {
            position
        }

        mutating func seek(to checkpoint: Int) {
            position = checkpoint
        }
    }
}
