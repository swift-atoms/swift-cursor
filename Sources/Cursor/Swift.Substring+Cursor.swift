public import Checkpoint
public import Iterator

extension Swift.Substring: @retroactive Iterator.`Protocol`, Cursor.`Protocol` {

    public typealias Failure = Never

    @inlinable
    public mutating func next() -> Character? {
        popFirst()
    }
}
