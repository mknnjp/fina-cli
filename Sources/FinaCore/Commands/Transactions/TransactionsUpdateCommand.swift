import ArgumentParser
import Foundation

public struct TransactionsUpdate: AsyncParsableCommand, FormatAware {
    public static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a single-split transaction."
    )

    @Argument(help: "Transaction ID.")
    public var id: String

    @Option(name: .long, help: "Transaction journal ID.")
    public var journalId: String?

    @Option(name: .long, help: "Transaction type.")
    public var type: String?

    @Option(name: .long, help: "Transaction date (YYYY-MM-DD).")
    public var date: String?

    @Option(name: .long, help: "Transaction amount.")
    public var amount: String?

    @Option(name: .long, help: "Transaction description.")
    public var description: String?

    @Option(name: .long, help: "Source account ID or name.")
    public var source: String?

    @Option(name: .long, help: "Destination account ID or name.")
    public var destination: String?

    @Option(name: .long, help: "Currency code.")
    public var currency: String?

    @OptionGroup public var globalOptions: GlobalOptions

    /// The positional id and required options are populated by the parser's
    /// decoder. Assigning placeholder values here would resolve the argument
    /// wrappers before parsing, which crashes swift-argument-parser.
    public init() {}

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }

    public func run() async throws {
        let fields = TransactionUpdateFields(
            type: type,
            date: date,
            amount: amount,
            description: description,
            source: source,
            destination: destination,
            currencyCode: currency,
            journalId: journalId
        )
        try TransactionInputValidator.validateUpdate(fields)
        let context = CommandContext(format: globalOptions.resolvedFormat)
        let client = try context.makeClient()
        let updatedId = try await client.updateTransaction(id: id, fields: fields)
        print(context.formatter.resultLines(id: updatedId, action: "Updated transaction"))
    }

    public mutating func validate() throws {
        globalOptions.recordDeclaredFormat()
    }
}
