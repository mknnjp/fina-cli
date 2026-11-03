import ArgumentParser
import Foundation
import Testing

@testable import FinaCore

// MARK: - Argument parsing

@Test func outputFormatParsesAcceptedValues() throws {
    #expect(OutputFormat(argument: "plain") == .plain)
    #expect(OutputFormat(argument: "json") == .json)
    #expect(OutputFormat(argument: "bogus") == nil)
    #expect(OutputFormat.acceptedValues == ["plain", "json"])
}

/// Parse a command line and return the deepest matched command instance.
/// `parseAsRoot` returns the leaf, not the root, so the root is inspected via
/// `Fina.parse` with no subcommand arguments.
///
/// These tests touch `FormatSelection.shared`, which the CLI populates during
/// parsing, so the suite is serialized to keep runs independent.
@Suite(.serialized) struct GlobalFormatOptionTests {
    /// Parse a command line and return the deepest matched command instance.
    private func parseRoot(_ arguments: [String]) throws -> any ParsableCommand {
        FormatSelection.shared.reset()
        return try Fina.parseAsRoot(arguments)
    }

    private func rootCommand(_ arguments: [String]) throws -> Fina {
        FormatSelection.shared.reset()
        return try Fina.parse(arguments)
    }

    private func leafCommand(_ arguments: [String]) throws -> any FormatAware {
        let command = try parseRoot(arguments)
        return try #require(command as? any FormatAware)
    }

    @Test func acceptedBeforeSubcommand() throws {
        // The root decodes the value; the leaf resolves to the same format.
        let command = try rootCommand(["--format", "json"])
        #expect(command.globalOptions.format == .json)
        #expect(command.globalOptions.resolvedFormat == .json)
        #expect(try leafCommand(["--format", "json", "accounts", "list"]).globalOptions.resolvedFormat == .json)
    }

    @Test func acceptedAfterSubcommand() throws {
        let list = try leafCommand(["accounts", "list", "--format", "json"])
        #expect(list is AccountsList)
        #expect(list.globalOptions.format == .json)
        #expect(list.globalOptions.resolvedFormat == .json)
    }

    @Test func usesShortFlag() throws {
        let command = try rootCommand(["-f", "json"])
        #expect(command.globalOptions.format == .json)
        #expect(command.globalOptions.resolvedFormat == .json)
    }

    @Test func defaultsToPlain() throws {
        // A directly-initialized `GlobalOptions()` cannot be read (the wrapped
        // value only exists after decoding), so assert through real parses.
        let list = try leafCommand(["accounts", "list"])
        #expect(list.globalOptions.format == nil)
        #expect(list.globalOptions.resolvedFormat == .plain)
        let transactions = try leafCommand(["transactions", "list"])
        #expect(transactions.globalOptions.format == nil)
        #expect(transactions.globalOptions.resolvedFormat == .plain)
    }

    @Test func rejectsUnknownValue() {
        #expect(throws: (any Error).self) {
            try Fina.parseAsRoot(["accounts", "list", "--format", "yaml"])
        }
    }

    @Test func outerFormatIsNotOverwrittenByInnerDefault() throws {
        let selection = FormatSelection()
        selection.reset()
        #expect(selection.resolve(declared: .json) == .json)
        #expect(selection.resolve(declared: nil) == .json)
        #expect(selection.resolve(declared: .plain) == .json)
        selection.reset()
        #expect(selection.resolve(declared: nil) == .plain)
        #expect(selection.resolve(declared: .json) == .json)
    }

    @Test func everyLeafCommandExposesTheFormatOption() throws {
        // Group commands list their leaves through `configuration`, not a property.
        let transactionLeaves = Transactions.configuration.subcommands
        #expect(transactionLeaves.count == 3)
        for leaf in transactionLeaves {
            #expect(leaf is any FormatAware.Type)
        }
        let accountLeaves = Accounts.configuration.subcommands
        #expect(accountLeaves.count == 1)
        for leaf in accountLeaves {
            #expect(leaf is any FormatAware.Type)
        }
        #expect(try leafCommand(["transactions", "list", "--format", "json"]).globalOptions.resolvedFormat == .json)
    }
}

// MARK: - Rendering

@Test func jsonAccountsTableIsSingleLineParseableJSON() throws {
    let output = OutputFormatter(format: .json).accountsTable([
        Account(id: "1", name: "Cash", type: "asset", currencyCode: "JPY", balance: "1000"),
        Account(id: "22", name: "Bank", type: "asset", currencyCode: "JPY", balance: "20000"),
    ])
    #expect(!output.contains("\n"))
    let parsed = try JSONSerialization.jsonObject(with: Data(output.utf8))
    let accounts = try #require((parsed as? [String: Any])?["accounts"] as? [[String: Any]])
    #expect(accounts.count == 2)
    #expect(accounts[1]["name"] as? String == "Bank")
    #expect(accounts[1]["balance"] as? String == "20000")
}

@Test func jsonTransactionsTableIsParseableWithEmptyResults() throws {
    let output = OutputFormatter(format: .json).transactionsTable([])
    let parsed = try JSONSerialization.jsonObject(with: Data(output.utf8))
    let transactions = try #require((parsed as? [String: Any])?["transactions"] as? [[String: Any]])
    #expect(transactions.isEmpty)
}

@Test func jsonResultLinesCarryActionAndId() throws {
    let output = OutputFormatter(format: .json).resultLines(id: "42", action: "Created transaction")
    let parsed = try JSONSerialization.jsonObject(with: Data(output.utf8))
    let object = try #require(parsed as? [String: Any])
    #expect(object["id"] as? String == "42")
    #expect(object["action"] as? String == "Created transaction")
}

@Test func errorLinesArePlainInPlainModeAndJsonInJsonMode() throws {
    #expect(OutputFormatter(format: .plain).errorLines("boom") == "boom")

    let json = OutputFormatter(format: .json).errorLines("boom")
    let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8))
    #expect((parsed as? [String: Any])?["error"] as? String == "boom")
}

@Test func errorMessageExtractionUsesLocalizedDescription() {
    let configError = ConfigError.missing(path: "/tmp/config.json")
    let message = CommandErrorReporter.message(for: configError)
    #expect(message.contains("/tmp/config.json"))
    #expect(message.contains("baseURL"))
    #expect(message.contains("token"))

    let plainError = CommandError("plain failure")
    #expect(CommandErrorReporter.message(for: plainError) == "plain failure")
}

@Test func errorMessageExtractionSkipsEmptyLocalizedDescription() {
    struct EmptyDescriptionError: LocalizedError, CustomStringConvertible {
        var errorDescription: String? { "" }
        var description: String { "empty-description fallback" }
    }
    let message = CommandErrorReporter.message(for: EmptyDescriptionError())
    #expect(!message.isEmpty)
}
