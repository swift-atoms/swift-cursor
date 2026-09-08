func proof() {
    var values = [10, 20]
    var cursor = BorrowedCursor(values.span)
    let result = advance(&cursor)!
    values.append(30)
    print(result[0])
}
