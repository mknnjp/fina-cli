import ArgumentParser
import Foundation

/// Output format selector selected by `--format`. `plain` is the default;
/// `json` renders machine-readable single-line documents.
public enum OutputFormat: String, CaseIterable, Equatable, ExpressibleByArgument, Sendable {
    case plain
    case json

    /// Accepted values for help text and error messages.
    public static var acceptedValues: [String] { allCases.map(\.rawValue) }
}

public protocol OutputRendering: Sendable {
    func accountsTable(_ accounts: [Account]) -> String
    func transactionsTable(_ transactions: [TransactionView]) -> String
    func resultLines(id: String, action: String) -> String
    func errorLines(_ message: String) -> String
}

/// Plain-text rendering for humans. No JSON output by default.
public struct OutputFormatter: OutputRendering, Sendable {
    public var format: OutputFormat

    public init(format: OutputFormat = .plain) {
        self.format = format
    }

    public func accountsTable(_ accounts: [Account]) -> String {
        switch format {
        case .plain:
            return TableFormatter().accountsTable(accounts)
        case .json:
            return JSONFormatter().accountsJSON(accounts)
        }
    }

    public func transactionsTable(_ transactions: [TransactionView]) -> String {
        switch format {
        case .plain:
            return TableFormatter().transactionsTable(transactions)
        case .json:
            return JSONFormatter().transactionsJSON(transactions)
        }
    }

    public func resultLines(id: String, action: String) -> String {
        switch format {
        case .plain:
            return ResultFormatter().resultLines(id: id, action: action)
        case .json:
            return JSONFormatter().resultJSON(id: id, action: action)
        }
    }

    /// Error text for the selected format. Plain mode returns the message
    /// unchanged; JSON mode wraps it in a single-key `error` object.
    public func errorLines(_ message: String) -> String {
        switch format {
        case .plain:
            return message
        case .json:
            return JSONFormatter().errorJSON(message)
        }
    }
}
