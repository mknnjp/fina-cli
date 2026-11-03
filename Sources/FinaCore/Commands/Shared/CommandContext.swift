import ArgumentParser
import Foundation

/// Shared helpers for commands (client construction, output).
public struct CommandContext: Sendable {
    public var clientFactory: ClientFactory
    public var formatter: OutputFormatter

    /// Build a context whose formatter honors the `--format` selection.
    public init(format: OutputFormat = .plain) {
        self.init(clientFactory: ClientFactory(), formatter: OutputFormatter(format: format))
    }

    public init(clientFactory: ClientFactory = ClientFactory(), formatter: OutputFormatter = OutputFormatter()) {
        self.clientFactory = clientFactory
        self.formatter = formatter
    }

    public func makeClient() throws -> FireflyClient {
        try clientFactory.makeClient()
    }
}
