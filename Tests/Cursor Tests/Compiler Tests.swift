#if os(macOS)
import Cursor
import Darwin
import Foundation
import Testing

extension Cursor::Cursor {
    @Suite
    struct `Compiler emission enforces cursor output ownership` {
        struct Compilation {
            let status: Int32
            let diagnostic: String
            let emittedObject: Bool
        }

        enum Failure: Swift.Error {
            case timedOut(String)
        }
    }
}

extension Cursor::Cursor.`Compiler emission enforces cursor output ownership` {
    @Test
    func `Fresh owned values can be emitted before and after seeking`() throws {
        let compilation = try Self.emit(named: "Valid Owned Replay.swift")

        #expect(compilation.status == 0, Comment(rawValue: compilation.diagnostic))
        #expect(compilation.emittedObject)
    }

    @Test
    func `Borrowed values can be emitted again after their previous last use`() throws {
        let compilation = try Self.emit(named: "Valid Borrowed Replay.swift")

        #expect(compilation.status == 0, Comment(rawValue: compilation.diagnostic))
        #expect(compilation.emittedObject)
    }

    @Test
    func `A noncopyable output cannot be consumed twice`() throws {
        let diagnostic = try Self.rejection(named: "Double Consume Output.swift")

        #expect(diagnostic.contains("'value' consumed more than once"))
    }

    @Test
    func `A borrowed output cannot outlive its local backing storage`() throws {
        let diagnostic = try Self.rejection(named: "Escape Borrowed Output.swift")

        #expect(diagnostic.contains("lifetime-dependent value escapes its scope"))
    }

    @Test
    func `A cursor cannot seek while its borrowed output remains in use`() throws {
        let diagnostic = try Self.rejection(named: "Mutate Cursor With Live Output.swift")

        #expect(diagnostic.contains("overlapping accesses to 'cursor', but modification requires exclusive access"))
    }

    @Test
    func `Backing storage cannot mutate while a borrowed output remains in use`() throws {
        let diagnostic = try Self.rejection(named: "Mutate Backing With Live Output.swift")

        #expect(diagnostic.contains("overlapping accesses to 'values', but modification requires exclusive access"))
    }

    private static func rejection(named name: String) throws -> String {
        let compilation = try emit(named: name)
        try #require(compilation.status != 0, "Fixture unexpectedly emitted successfully")
        return compilation.diagnostic
    }

    private static func emit(named name: String) throws -> Compilation {
        let manager = FileManager.default
        var products = Bundle.module.bundleURL
        while !manager.fileExists(atPath: products.appendingPathComponent("Cursor.swiftmodule").path) {
            let parent = products.deletingLastPathComponent()
            products = try #require(parent != products ? parent : nil)
        }
        let resource = try #require(Bundle.module.resourceURL)
        let fixtures = resource.appendingPathComponent("Fixtures")
        let fixture = fixtures.appendingPathComponent(name)
        let support = fixtures.appendingPathComponent("Support.swift")
        try #require(manager.fileExists(atPath: fixture.path))
        try #require(manager.fileExists(atPath: support.path))

        let directory = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: directory) }
        let diagnosticURL = directory.appendingPathComponent("diagnostic.txt")
        try #require(manager.createFile(atPath: diagnosticURL.path, contents: nil))
        let diagnosticFile = try FileHandle(forWritingTo: diagnosticURL)
        defer { try? diagnosticFile.close() }
        let object = directory.appendingPathComponent("Proof.o")

        #if DEBUG
        let optimization = "-Onone"
        #else
        let optimization = "-O"
        #endif

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "swiftc", "-c", "-whole-module-optimization", "-parse-as-library", optimization,
            "-swift-version", "6",
            "-enable-experimental-feature", "Lifetimes",
            "-module-name", "Proof",
            "-I", products.path,
            support.path, fixture.path,
            "-o", object.path,
        ]
        process.standardOutput = diagnosticFile
        process.standardError = diagnosticFile
        try process.run()
        defer {
            if process.isRunning {
                _ = Darwin.kill(process.processIdentifier, SIGKILL)
            }
        }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(30))
        while process.isRunning && clock.now < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        guard !process.isRunning else {
            process.interrupt()
            let cancellationDeadline = clock.now.advanced(by: .seconds(1))
            while process.isRunning && clock.now < cancellationDeadline {
                Thread.sleep(forTimeInterval: 0.01)
            }
            throw Failure.timedOut(name)
        }
        process.waitUntilExit()
        let diagnostic = try String(contentsOf: diagnosticURL, encoding: .utf8)
        try #require(process.terminationReason == .exit, Comment(rawValue: diagnostic))
        for failure in ["no such module", "missing required module", "could not build module", "compiled module was created by a different version"] {
            try #require(!diagnostic.contains(failure), Comment(rawValue: diagnostic))
        }
        return Compilation(
            status: process.terminationStatus,
            diagnostic: diagnostic,
            emittedObject: manager.fileExists(atPath: object.path)
        )
    }
}
#endif
