func proof() {
    var cursor = ProducingCursor()
    let value = advance(&cursor)!
    discard(value)
    discard(value)
}
