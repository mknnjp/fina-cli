import Foundation

/// Renders runtime errors in the selected output format.
///
/// Errors are user-facing plain text in every error type (`ConfigError`,
/// `FireflyError`, `TransactionInputError`, `SingleSplitError`), so only the
/// rendering differs by format. Messages always go to stderr to keep stdout
/// reserved for results.
public enum CommandErrorReporter {
    /// Extract the user-facing message from an error.
    ///
    /// Prefers `LocalizedError.errorDescription`, then
    /// `localizedDescription`, and finally `String(describing:)` so the result is
    /// never empty.
    public static func message(for error: Error) -> String {
        if let localized = error as? any LocalizedError,
            let description = localized.errorDescription,
            !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return description
        }
        let localized = error.localizedDescription
        if !localized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return localized
        }
        return String(describing: error)
    }

    /// Write the rendered error to stderr.
    public static func report(_ error: Error, format: OutputFormat) {
        let line = OutputFormatter(format: format).errorLines(message(for: error))
        write(line + "\n")
    }

    static func write(_ text: String) {
        FileHandle.standardError.write(Data(text.utf8))
    }
}
