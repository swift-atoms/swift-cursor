func proof() {
    var cursor = ProducingCursor()
    let mark = cursor.checkpoint
    let first = advance(&cursor)!
    cursor.seek(to: mark)
    let replay = advance(&cursor)!
    precondition(first.value == replay.value)
    discard(first)
    discard(replay)
}
