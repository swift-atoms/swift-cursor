public import Checkpoint
public import Iterator

extension Swift.ArraySlice: @retroactive Iterator.`Protocol`, Cursor.`Protocol`
where Element: Equatable {

    public typealias Failure = Never

    @inlinable
    public mutating func next() -> Element? {
        popFirst()
    }
}
