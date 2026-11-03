import ArgumentParser
import Foundation

/// Options shared by every command in the tree.
///
/// ArgumentParser has no inherited global options, so this group is attached to
/// each command (root, groups, and leaves). Because each command decodes its own
/// copy, a value given before a subcommand (`fina --format json accounts list`)
/// lands only on the root instance. `FormatSelection` records the first
/// non-`nil` value seen so the effective format is identical wherever the
/// flag appears.
public struct GlobalOptions: ParsableArguments, Sendable {
    public static var allValueStrings: [String] { OutputFormat.acceptedValues }

    @Option(
        name: [.customShort("f"), .customLong("format")],
        help: "Output format: \(OutputFormat.acceptedValues.joined(separator: ", "))."
    )
    public var format: OutputFormat? = nil

    public init() {}

    public init(format: OutputFormat?) {
        self.format = format
    }

    /// Effective format for this command, falling back to a value supplied at
    /// an outer command level.
    public var resolvedFormat: OutputFormat {
        FormatSelection.shared.resolve(declared: format)
    }

    /// Record this command's declared value so deeper commands can fall back to
    /// it. Called from each command's `validate()`, which ArgumentParser invokes
    /// while descending from the root to the matched leaf.
    public mutating func recordDeclaredFormat() {
        FormatSelection.shared.record(declared: format)
    }
}

/// Process-wide record of the `--format` value supplied on the command line.
///
/// ArgumentParser decodes the root command before descending, so the root's
/// value is recorded first and reused by deeper commands that did not receive
/// the flag themselves.
public final class FormatSelection: @unchecked Sendable {
    public static let shared = FormatSelection()

    private let lock = NSLock()
    private var recorded: OutputFormat?

    public init() {}

    /// Record a non-`nil` declared value. The first one seen wins, so a value
    /// given at an outer level is not overwritten by inner defaults.
    public func record(declared: OutputFormat?) {
        guard let declared else { return }
        lock.lock()
        defer { lock.unlock() }
        if recorded == nil { recorded = declared }
    }

    /// Resolve the effective format, recording `declared` first.
    public func resolve(declared: OutputFormat?) -> OutputFormat {
        record(declared: declared)
        lock.lock()
        defer { lock.unlock() }
        return recorded ?? .plain
    }

    /// Clear recorded state. Intended for tests.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        recorded = nil
    }
}
