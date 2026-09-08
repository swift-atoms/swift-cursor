func proof(_ values: Span<Int>) {
    var cursor = BorrowedCursor(values)
    let mark = cursor.checkpoint
    let result = advance(&cursor)!
    cursor.seek(to: mark)
    print(result[0])
}
