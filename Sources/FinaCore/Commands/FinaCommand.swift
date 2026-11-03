import ArgumentParser
import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

public struct Fina: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "fina",
        abstract: "Swift-native CLI for Firefly III.",
        subcommands: [Accounts.self, Transactions.self]
    )

    @OptionGroup public var globalOptions: GlobalOptions

    public init() {}

    /// Owns error rendering so runtime failures honor `--format`.
    ///
    /// Parse failures (including `--help` and an unknown `--format` value) are
    /// delegated to ArgumentParser unchanged, keeping help and usage output
    /// plain text.
    public static func main() async {
        do {
            // `asyncParseAsRoot` returns the deepest matched command (not
            // `Self`), which is the one that actually runs.
            var command = try await Self.asyncParseAsRoot()
            // Built-in commands (help, version) are not `FormatAware`; their
            // errors stay with ArgumentParser.
            let format = (command as? FormatAware)?.globalOptions.resolvedFormat
            do {
                if var asyncCommand = command as? AsyncParsableCommand {
                    try await asyncCommand.run()
                } else {
                    try command.run()
                }
            } catch {
                guard let format else { Self.exit(withError: error) }
                CommandErrorReporter.report(error, format: format)
                Foundation.exit(EXIT_FAILURE)
            }
        } catch {
            // Parse failures (help, version, usage, bad option values) keep
            // ArgumentParser's plain-text behavior.
            Self.exit(withError: error)
        }
    }

    public func run() async throws {
        throw CommandError("No subcommand specified.")
    }

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}

/// Any command carrying the shared `--format` selection.
public protocol FormatAware {
    var globalOptions: GlobalOptions { get }
}

/// Wrapper for an error that has no dedicated error type.
public struct CommandError: Error, LocalizedError {
    public var message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}
