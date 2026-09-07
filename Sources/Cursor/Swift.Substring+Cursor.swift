public import Checkpoint
public import Iterator

extension Swift.Substring: @retroactive Iterator.`Protocol`, @retroactive Restorable, Cursor.`Protocol` {

    public typealias Failure = Never

    public typealias Checkpoint = Self

    @inlinable
    public mutating func next() -> Character? {
        popFirst()
    }
}
