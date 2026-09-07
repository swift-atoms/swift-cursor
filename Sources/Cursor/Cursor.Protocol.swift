public import Checkpoint
public import Iterator

extension Cursor {

    public protocol `Protocol`<Element, Failure>: Iterator.`Protocol`, Restorable, ~Copyable, ~Escapable
    where Checkpoint: Equatable {}
}
