@_lifetime(borrow anchor)
func proof(_ anchor: borrowing [Int]) -> Span<Int> {
    let values = [10, 20]
    var cursor = BorrowedCursor(values.span)
    return advance(&cursor)!
}
