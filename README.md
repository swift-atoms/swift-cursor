# swift-cursor

Use this package when you iterate input and need to back up: a parser or scanner that tries one reading, rewinds to a saved position and tries another. Start from `Cursor.Protocol`, which is an `Iterator.Protocol` that is also `Restorable` with an `Equatable` checkpoint. `Swift.Substring` and, when its elements are `Equatable`, `Swift.ArraySlice` already conform, and `Cursor.Collection<Base>` wraps any other collection. If you only iterate forward, use `Iterator.Protocol` from swift-iterator. If you need save and restore without iteration, use `Restorable` from swift-checkpoint.

## Laws

- Every conformer must satisfy the restoration laws in `RestorableLaws`. Seeking to the current checkpoint changes nothing. Seeking to a saved checkpoint after any number of `next()` calls restores the observable position.
- Seeking does not take back an element that was already returned. When a cursor's elements are owned, a replay produces a new value, and earlier values stay alive and separate from it. When they are borrowed, the cursor cannot seek, and the backing storage cannot change, while a borrowed element is still in use. The compiler enforces both, and the compiler tests pin them.
- A `Swift.ArraySlice` or `Swift.Substring` checkpoint is a snapshot of the whole slice: its bounds and its contents at the moment it was taken. Seeking replaces the current slice with that snapshot, even if the cursor was mutated or reassigned in between. Two checkpoints are equal when they have the same start index, whatever their contents or source. So equal content at different positions compares unequal, and different content at the same position compares equal.
- A `Swift.ArraySlice` or `Swift.Substring` cursor that is exhausted keeps returning `nil`.
- A `Cursor.Collection` checkpoint is an index of the base collection. Seeking checks that the index belongs to the base by walking from `startIndex`, so each seek costs linear time. `endIndex` is accepted. An index that does not belong to the base traps in `Cursor.Collection.seek(to:)` and throws in `Cursor.Collection.restore(to:)`.
- `Cursor.Collection.removeFirst(_:)` is all-or-nothing. If the count is negative or larger than the number of remaining elements, it throws and the position does not change. `Cursor.Collection.element(at:)` counts offsets from the current position, not from the start of the base.
