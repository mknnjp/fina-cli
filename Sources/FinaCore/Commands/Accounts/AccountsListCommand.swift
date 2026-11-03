import ArgumentParser
import Foundation

public struct Accounts: AsyncParsableCommand, FormatAware {
    public static let configuration = CommandConfiguration(
        commandName: "accounts",
        abstract: "Manage accounts.",
        subcommands: [AccountsList.self]
    )

    @OptionGroup public var globalOptions: GlobalOptions

    public init() {}

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}

public struct AccountsList: AsyncParsableCommand, FormatAware {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List accounts with balances."
    )

    @OptionGroup public var globalOptions: GlobalOptions

    public init() {}

    public func run() async throws {
        let context = CommandContext(format: globalOptions.resolvedFormat)
        let client = try context.makeClient()
        let accounts = try await client.listAccounts()
        print(context.formatter.accountsTable(accounts))
    }

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}
