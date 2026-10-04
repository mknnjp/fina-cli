import Foundation

/// JSON rendering for `--format json`. Emits compact single-line documents
/// with sorted keys so output stays machine-parseable.
public struct JSONFormatter: Sendable {
    public init() {}

    public func accountsJSON(_ accounts: [Account]) -> String {
        let rows = accounts.map { ["id": $0.id, "name": $0.name, "type": $0.type, "currency": $0.currencyCode, "balance": $0.balance] }
        return jsonString(["accounts": rows])
    }

    public func transactionsJSON(_ transactions: [TransactionView]) -> String {
        let rows = transactions.map {
            ["id": $0.id, "date": $0.date, "description": $0.description, "type": $0.type,
             "amount": $0.amount, "source": $0.source, "destination": $0.destination]
        }
        return jsonString(["transactions": rows])
    }

    public func resultJSON(id: String, action: String) -> String {
        jsonString(["action": action, "id": id])
    }

    public func errorJSON(_ message: String) -> String {
        jsonString(["error": message])
    }

    private func jsonString(_ value: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8)
        else { return "{}" }
        return text
    }
}
