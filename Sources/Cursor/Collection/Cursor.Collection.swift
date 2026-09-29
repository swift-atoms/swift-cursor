#if Collection
import Checkpoint
import Iterator

extension Cursor {
    public enum CollectionError: Swift.Error, Equatable {
        case empty
        case insufficientElements(requested: Int, available: Int)
        case invalidCheckpoint
        case invalidOffset(Int)
    }

    public struct Collection<Base: Swift.Collection>: Cursor.`Protocol` {
        public typealias Element = Base.Element
        public typealias Failure = Never
        public typealias Checkpoint = Base.Index
        private let base: Base
        private var position: Base.Index

        public init(_ base: Base) { self.base = base; self.position = base.startIndex }
        public var checkpoint: Checkpoint { position }
        public var count: Int { base.distance(from: position, to: base.endIndex) }
        public var consumed: Int { base.distance(from: base.startIndex, to: position) }
        public var isEmpty: Bool { position == base.endIndex }
        public var first: Element? { isEmpty ? nil : base[position] }
        public var remaining: Base.SubSequence { base[position...] }

        public mutating func next() -> Element? {
            guard !isEmpty else { return nil }
            let element = base[position]
            base.formIndex(after: &position)
            return element
        }
        private func isValid(_ candidate: Base.Index) -> Bool {
            var index = base.startIndex
            while index != base.endIndex {
                if index == candidate { return true }
                base.formIndex(after: &index)
            }
            return candidate == base.endIndex
        }
        public mutating func seek(to checkpoint: Checkpoint) {
            precondition(isValid(checkpoint), "Checkpoint is not an index in this collection")
            position = checkpoint
        }
        public mutating func restore(to checkpoint: Checkpoint) throws(Cursor.CollectionError) {
            guard isValid(checkpoint) else { throw .invalidCheckpoint }
            position = checkpoint
        }
        @discardableResult
        public mutating func removeFirst() throws(Cursor.CollectionError) -> Element {
            guard let value = next() else { throw .empty }
            return value
        }
        public mutating func removeFirst(_ count: Int) throws(Cursor.CollectionError) {
            let available = self.count
            guard count >= 0, count <= available else {
                throw .insufficientElements(requested: count, available: available)
            }
            position = base.index(position, offsetBy: count)
        }
        public func element(at offset: Int) throws(Cursor.CollectionError) -> Element {
            guard offset >= 0, offset < count else { throw .invalidOffset(offset) }
            return base[base.index(position, offsetBy: offset)]
        }
    }
}
extension Cursor.Collection: Sendable where Base: Sendable, Base.Index: Sendable {}
#endif
