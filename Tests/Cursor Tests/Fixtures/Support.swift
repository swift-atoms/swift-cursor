import Cursor

struct OwnedValue: ~Copyable {
    let value: Int
}

struct ProducingCursor: Cursor.`Protocol`, ~Copyable {
    typealias Element = OwnedValue
    typealias Failure = Never

    var position = 0
    var checkpoint: Int { position }

    mutating func seek(to checkpoint: Int) {
        position = checkpoint
    }

    mutating func next() -> OwnedValue? {
        guard position < 2 else { return nil }
        defer { position += 1 }
        return OwnedValue(value: position)
    }
}

struct BorrowedCursor: Cursor.`Protocol`, ~Copyable, ~Escapable {
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

@_lifetime(&cursor)
func advance<C: Cursor.`Protocol` & ~Copyable & ~Escapable>(
    _ cursor: inout C
) throws(C.Failure) -> C.Element?
where C.Element: ~Copyable & ~Escapable {
    try cursor.next()
}

func discard(_ value: consuming OwnedValue) {}
