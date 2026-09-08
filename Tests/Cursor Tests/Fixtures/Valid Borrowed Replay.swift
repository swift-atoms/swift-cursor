func proof(_ values: Span<Int>) {
    var cursor = BorrowedCursor(values)
    let mark = cursor.checkpoint
    do {
        let result = advance(&cursor)!
        precondition(result[0] == values[0])
    }
    cursor.seek(to: mark)
    let replay = advance(&cursor)!
    precondition(replay[0] == values[0])
}
