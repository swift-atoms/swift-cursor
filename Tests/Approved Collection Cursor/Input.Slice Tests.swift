#if Collection
import Cursor
import Testing


    @Suite
    enum `Collection Cursor Test` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }


extension `Collection Cursor Test`.Unit {
    @Test
    func `init from collection`() throws {
        let collection = [1, 2, 3, 4, 5]
        let slice = Cursor.Collection(collection)
        let expectedCount = 5
        #expect(slice.count == expectedCount)
        #expect(slice.first == 1)
        #expect(!slice.isEmpty)
    }

    @Test
    func `isEmpty returns true for empty slice`() throws {
        let collection: [Int] = []
        let slice = Cursor.Collection(collection)
        #expect(slice.isEmpty)
        let expectedCount = 0
        #expect(slice.count == expectedCount)
        #expect(slice.first == nil)
    }

    @Test
    func `collection traversal follows the current input position`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        _ = try slice.removeFirst()

        #expect(Array(slice.remaining) == [2, 3])

        let remaining = slice.remaining
        #expect(Array(remaining) == [2, 3])
    }

    @Test
    func `removeFirst() consumes element`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        let first = try slice.removeFirst()
        #expect(first == 1)
        let expectedCount = 2
        #expect(slice.count == expectedCount)
        #expect(slice.first == 2)
    }

    @Test
    func `removeFirst(n) advances by n elements`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        var slice = Cursor.Collection(collection)
        let three = 3
        try slice.removeFirst(three)
        let expectedCount = 2
        #expect(slice.count == expectedCount)
        #expect(slice.first == 4)
    }

    @Test
    func `checkpoint returns current position`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        var slice = Cursor.Collection(collection)
        _ = try slice.removeFirst()
        let cp = slice.checkpoint
        _ = try slice.removeFirst()
        #expect(slice.first == 3)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cp)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(slice.first == 2)
    }

    @Test
    func `checkpoint and restore roundtrip`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        var slice = Cursor.Collection(collection)
        let cp = slice.checkpoint
        _ = try slice.removeFirst()
        _ = try slice.removeFirst()
        let expectedCount3 = 3
        #expect(slice.count == expectedCount3)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cp)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        let expectedCount5 = 5
        #expect(slice.count == expectedCount5)
        #expect(slice.first == 1)
    }

    @Test
    func `subscript offset access`() throws {
        let collection = [10, 20, 30, 40, 50]
        let slice = Cursor.Collection(collection)
        let offset0 = 0
        let offset2 = 2
        let offset4 = 4
        #expect(try slice.element(at: offset0) == 10)
        #expect(try slice.element(at: offset2) == 30)
        #expect(try slice.element(at: offset4) == 50)
    }

    @Test
    func `remaining returns self`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        _ = try slice.removeFirst()
        let remaining = slice.remaining
        #expect(remaining.count == slice.count)
        #expect(remaining.first == slice.first)
    }

    @Test
    func `removeFirst() throws when empty`() throws {
        let collection: [Int] = []
        var slice = Cursor.Collection(collection)
        #expect(throws: Cursor.CollectionError.empty) {
            try slice.removeFirst()
        }
    }

    @Test
    func `try? removeFirst() returns nil when empty`() throws {
        let collection: [Int] = []
        var slice = Cursor.Collection(collection)
        let result: Int?
        do throws(Cursor.CollectionError) {
            result = try slice.removeFirst()
        } catch {
            result = nil
        }
        #expect(result == nil)
        #expect(slice.isEmpty)
    }

    @Test
    func `try? removeFirst() consumes element`() throws {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        let result: Int?
        do throws(Cursor.CollectionError) {
            result = try slice.removeFirst()
        } catch {
            result = nil
        }
        #expect(result == 1)
        #expect(slice.first == 2)
        let expectedCount = 2
        #expect(slice.count == expectedCount)
    }
}

extension `Collection Cursor Test`.`Edge Case` {
    @Test
    func `single element slice`() throws(Cursor.CollectionError) {
        let collection = [42]
        var slice = Cursor.Collection(collection)
        #expect(!slice.isEmpty)
        #expect(slice.first == 42)
        let cp = slice.checkpoint
        #expect(try slice.removeFirst() == 42)
        #expect(slice.isEmpty)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cp)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(slice.first == 42)
    }

    @Test
    func `restore to checkpoint at end`() throws(Cursor.CollectionError) {
        let collection = [1, 2]
        var slice = Cursor.Collection(collection)
        _ = try slice.removeFirst()
        _ = try slice.removeFirst()
        let cpAtEnd = slice.checkpoint
        #expect(slice.isEmpty)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cpAtEnd)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(slice.isEmpty)
    }

    @Test
    func `nested checkpoint restore`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        var slice = Cursor.Collection(collection)
        let cp1 = slice.checkpoint
        _ = try slice.removeFirst()
        let cp2 = slice.checkpoint
        _ = try slice.removeFirst()
        _ = try slice.removeFirst()
        #expect(slice.first == 4)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cp2)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(slice.first == 2)
        do throws(Cursor.CollectionError) {
            try slice.restore(to: cp1)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(slice.first == 1)
    }

    @Test
    func `removeFirst(0) is no-op`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        let zero = 0
        try slice.removeFirst(zero)
        let expectedCount = 3
        #expect(slice.count == expectedCount)
        #expect(slice.first == 1)
    }

    @Test
    func `offset access after partial consumption`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        var slice = Cursor.Collection(collection)
        let two = 2
        try slice.removeFirst(two)
        let offset0 = 0
        let offset2 = 2
        #expect(try slice.element(at: offset0) == 3)
        #expect(try slice.element(at: offset2) == 5)
    }

    @Test
    func `removeFirst(n) throws when n > count`() throws {
        let collection = [1, 2, 3]
        var slice = Cursor.Collection(collection)
        let five = 5
        let three = 3
        #expect(
            throws: Cursor.CollectionError.insufficientElements(requested: five, available: three)
        ) {
            try slice.removeFirst(five)
        }
    }
}

extension `Collection Cursor Test`.Integration {
    @Test
    func `byte parsing scenario`() throws(Cursor.CollectionError) {
        let bytes = [UInt8](arrayLiteral: 0x48, 0x65, 0x6C, 0x6C, 0x6F)
        var input = Cursor.Collection(bytes)

        let cp = input.checkpoint
        _ = try input.removeFirst()
        _ = try input.removeFirst()
        #expect(input.first == 0x6C)

        do throws(Cursor.CollectionError) {
            try input.restore(to: cp)
        } catch {
            Issue.record("restore(to:) failed: \(error)")
            return
        }
        #expect(input.first == 0x48)
    }

    @Test
    func `element(at:) total accessor`() throws(Cursor.CollectionError) {
        let collection = [1, 2, 3, 4, 5]
        let input = Cursor.Collection(collection)
        let offset0 = 0
        let offset4 = 4

        let v0 = try input.element(at: offset0)
        let v4 = try input.element(at: offset4)
        #expect(v0 == 1)
        #expect(v4 == 5)
        let offset10 = 10
        var threw = false
        do throws(Cursor.CollectionError) {
            _ = try input.element(at: offset10)
        } catch {
            threw = true
        }
        #expect(threw)
    }
}
#endif
