public import Checkpoint
public import Iterator

extension Swift.ArraySlice: @retroactive Iterator.`Protocol`, @retroactive Restorable, Cursor.`Protocol`
where Element: Equatable {

    public typealias Failure = Never

    public typealias Checkpoint = Self

    @inlinable
    public mutating func next() -> Element? {
        popFirst()
    }
}
