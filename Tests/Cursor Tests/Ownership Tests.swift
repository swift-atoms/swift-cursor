import Cursor
import Synchronization
import Testing

extension Cursor {
    @Suite
    struct `Cursors preserve output ownership` {
        final class Counts: Sendable {
            let state = Mutex((created: 0, destroyed: 0, cursors: 0))

            func create() -> Int {
                state.withLock {
                    $0.created += 1
                    return $0.created
                }
            }

            func destroy() {
                state.withLock { $0.destroyed += 1 }
            }

            func cursorDestroyed() {
                state.withLock { $0.cursors += 1 }
            }

            var created: Int { state.withLock { $0.created } }
            var destroyed: Int { state.withLock { $0.destroyed } }
            var cursors: Int { state.withLock { $0.cursors } }
        }

        struct Token: ~Copyable {
            let value: Int
            let serial: Int
            let counts: Counts

            init(_ value: Int, counts: Counts) {
                self.value = value
                self.counts = counts
                self.serial = counts.create()
            }

            deinit { counts.destroy() }
        }

        enum ReadError: Swift.Error, Equatable {
            case rejected(Int)
        }

        struct Generator: Cursor.`Protocol`, ~Copyable {
            typealias Element = Token
            typealias Failure = ReadError

            var position = 0
            let counts: Counts

            var checkpoint: Int { position }

            mutating func seek(to checkpoint: Int) {
                position = checkpoint
            }

            mutating func next() throws(ReadError) -> Token? {
                if position == 2 {
                    position += 1
                    throw .rejected(2)
                }
                guard position < 2 else { return nil }
                defer { position += 1 }
                return Token(position + 100, counts: counts)
            }

            deinit { counts.cursorDestroyed() }
        }

        struct Borrowed: Cursor.`Protocol`, ~Copyable, ~Escapable {
            typealias Element = Span<Int>
            typealias Failure = Never

            let values: Span<Int>
            var position = 0

            @_lifetime(copy values)
            init(_ values: Span<Int>) {
                self.values = values
            }

            var checkpoint: Int { position }

            mutating func seek(to checkpoint: Int) {
                position = checkpoint
            }

            @_lifetime(&self)
            mutating func next() -> Span<Int>? {
                guard position < values.count else { return nil }
                let result = values.extracting(position..<(position + 1))
                position += 1
                return result
            }
        }

        struct Plain {
            let value: Int
        }

        struct PlainCursor: Cursor.`Protocol` {
            typealias Element = Plain
            typealias Failure = Never

            var position = 0
            var checkpoint: Int { position }

            mutating func seek(to checkpoint: Int) {
                position = checkpoint
            }

            mutating func next() -> Plain? {
                guard position == 0 else { return nil }
                position += 1
                return Plain(value: 42)
            }
        }
    }
}

extension Cursor.`Cursors preserve output ownership` {
    @Test
    func `Seeking can produce a fresh owned value while the previous value remains alive`() throws {
        let counts = Self.Counts()
        do {
            var cursor = Self.Generator(counts: counts)
            let mark = cursor.checkpoint
            let first = try Self.advance(&cursor)!
            let firstSerial = Self.read(first, expected: 100)
            cursor.seek(to: mark)
            let replay = try Self.advance(&cursor)!
            let replaySerial = Self.read(replay, expected: 100)

            #expect(firstSerial != replaySerial)
            #expect(counts.created == 2)
            #expect(counts.destroyed == 0)
            Self.discard(first)
            #expect(counts.destroyed == 1)
            Self.discard(replay)
            #expect(counts.destroyed == 2)
        }
        #expect(counts.cursors == 1)
    }

    @Test
    func `An owned output can outlive its noncopyable cursor`() throws {
        let counts = Self.Counts()
        let token = try Self.produce(counts)

        #expect(counts.cursors == 1)
        #expect(counts.destroyed == 0)
        _ = Self.read(token, expected: 100)
        Self.discard(token)
        #expect(counts.destroyed == 1)
    }

    @Test
    func `Dropping an unextracted owned output destroys it exactly once`() throws {
        let counts = Self.Counts()
        do {
            var cursor = Self.Generator(counts: counts)
            _ = try Self.advance(&cursor)
            #expect(counts.created == 1)
            #expect(counts.destroyed == 1)
        }
        #expect(counts.cursors == 1)
        #expect(counts.destroyed == 1)
    }

    @Test
    func `Typed failures preserve their payload and explicit restoration replays them`() throws {
        let counts = Self.Counts()
        var cursor = Self.Generator(counts: counts)
        _ = try Self.advance(&cursor)
        _ = try Self.advance(&cursor)
        let mark = cursor.checkpoint

        do {
            _ = try Self.advance(&cursor)
            Issue.record("Expected the cursor's typed failure")
        } catch {
            #expect(error == .rejected(2))
        }
        #expect(cursor.checkpoint == 3)
        cursor.seek(to: mark)
        do {
            _ = try Self.advance(&cursor)
            Issue.record("Expected the restored cursor's typed failure")
        } catch {
            #expect(error == .rejected(2))
        }
        #expect(counts.created == 2)
        #expect(counts.destroyed == 2)
    }

    @Test
    func `A nonescapable cursor replays borrowed spans after their last use`() {
        let values = [10, 20]
        Self.replay(values.span)
    }

    @Test
    func `A cursor can produce elements that do not conform to Equatable`() {
        var cursor = Self.PlainCursor()
        let mark = cursor.checkpoint

        #expect(Self.advance(&cursor)?.value == 42)
        #expect(Self.advance(&cursor) == nil)
        cursor.seek(to: mark)
        #expect(Self.advance(&cursor)?.value == 42)
    }

    @_lifetime(&cursor)
    private static func advance<C: Cursor.`Protocol` & ~Copyable & ~Escapable>(
        _ cursor: inout C
    ) throws(C.Failure) -> C.Element?
    where C.Element: ~Copyable & ~Escapable {
        try cursor.next()
    }

    private static func read(_ token: borrowing Token, expected: Int) -> Int {
        let value = token.value
        #expect(value == expected)
        return token.serial
    }

    private static func discard(_ token: consuming Token) {}

    private static func produce(_ counts: Counts) throws(ReadError) -> Token {
        var cursor = Generator(counts: counts)
        return try advance(&cursor)!
    }

    private static func replay(_ values: Span<Int>) {
        var cursor = Borrowed(values)
        let mark = cursor.checkpoint
        do {
            let part = advance(&cursor)!
            let count = part.count
            let value = part[0]
            #expect(count == 1)
            #expect(value == 10)
        }
        cursor.seek(to: mark)
        do {
            let part = advance(&cursor)!
            let value = part[0]
            #expect(value == 10)
        }
        do {
            let part = advance(&cursor)!
            let value = part[0]
            #expect(value == 20)
        }
        let exhausted = advance(&cursor) == nil
        #expect(exhausted)
    }
}
