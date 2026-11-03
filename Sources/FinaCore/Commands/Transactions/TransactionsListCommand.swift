import ArgumentParser
import Foundation

public struct Transactions: AsyncParsableCommand, FormatAware {
    public static let configuration = CommandConfiguration(
        commandName: "transactions",
        abstract: "Manage transactions.",
        subcommands: [TransactionsList.self, TransactionsCreate.self, TransactionsUpdate.self]
    )

    @OptionGroup public var globalOptions: GlobalOptions

    public init() {}

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}

public struct TransactionsList: AsyncParsableCommand, FormatAware {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List transactions."
    )

    @OptionGroup public var globalOptions: GlobalOptions

    @Option(name: .long, help: "Maximum number of transactions.")
    public var limit: Int?

    @Option(name: .long, help: "Filter by account ID or name.")
    public var account: String?

    public init() {}

    public init(limit: Int? = nil, account: String? = nil) {
        self.limit = limit
        self.account = account
        self.globalOptions = GlobalOptions()
    }

    public func run() async throws {
        let context = CommandContext(format: globalOptions.resolvedFormat)
        let client = try context.makeClient()
        let transactions = try await client.listTransactions(limit: limit, account: account)
        print(context.formatter.transactionsTable(transactions))
    }

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}
