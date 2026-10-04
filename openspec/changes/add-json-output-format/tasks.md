# Tasks

## 1. Output format plumbing

- [x] 1.1 Add `CaseIterable` and `ExpressibleByArgument` conformances to `OutputFormat` in `Sources/FinaCore/Output/OutputFormat.swift` and verify `swift build` succeeds
- [x] 1.2 Add `errorJSON(_ message: String) -> String` to `JSONFormatter` emitting a single-key `error` object, and verify it matches the existing compact sorted-keys style
- [x] 1.3 Add `errorLines(_ message: String) -> String` to `OutputFormatter` and to the `OutputRendering` protocol (message unchanged for `plain`, delegating to `errorJSON` for `json`), and verify `swift build` succeeds with `OutputFormatter` as the sole conformer
- [x] 1.4 Create `Sources/FinaCore/Commands/Shared/GlobalOptions.swift` with a `ParsableArguments, Sendable` struct holding `--format` / `-f` as an optional `OutputFormat` plus a `FormatSelection` record so an outer-level value reaches the executed leaf, and verify it compiles
- [x] 1.5 Add a `format: OutputFormat = .plain` parameter to `CommandContext` that builds `OutputFormatter(format:)`, keeping the existing `formatter` parameter for compatibility, and verify `swift build` succeeds
- [x] 1.6 Create `Sources/FinaCore/Commands/Shared/CommandErrorReporter.swift` with `message(for:)` extracting `LocalizedError.errorDescription` and `report(_:format:)` writing to stderr, and verify `swift build` succeeds

## 2. Command wiring

- [x] 2.1 Attach `@OptionGroup GlobalOptions` to `Fina` in `Sources/FinaCore/Commands/FinaCommand.swift` and verify `swift build` succeeds
- [x] 2.2 Implement `Fina.main() async` to delegate parse failures to `Fina.exit(withError:)` and route runtime errors through `CommandErrorReporter` before exiting non-zero, and verify `fina --help` still prints help and exits zero
- [x] 2.3 Attach `@OptionGroup GlobalOptions` to `Accounts` and `AccountsList`, implement `validate()` to record the declared format, pass `resolvedFormat` into `CommandContext`, and verify `swift build` succeeds
- [x] 2.4 Attach `@OptionGroup GlobalOptions` to `Transactions`, `TransactionsList`, `TransactionsCreate`, and `TransactionsUpdate`, implement `validate()` on each, initialize it in `TransactionsList`'s test-facing `init(limit:account:)`, pass `resolvedFormat` into `CommandContext`, and verify `swift build` succeeds

## 3. Tests

- [x] 3.1 Add `Tests/finaTests/OutputFormatTests.swift` covering `OutputFormat(argument:)` accepting `plain` and `json` and rejecting an unknown value, and verify the tests pass
- [x] 3.2 Add tests asserting `Fina.parseAsRoot` accepts `--format json` both before and after the subcommand path, and verify the tests pass
- [x] 3.3 Add tests asserting JSON list output is a single line that `JSONSerialization` parses, `errorLines` returns `{"error":...}` for `json` and the bare message for `plain`, `CommandErrorReporter.message(for:)` includes the config path and required fields, and the default format is `plain`, and verify the tests pass
- [x] 3.4 Run the full `swift test` suite and verify all pre-existing tests pass with no regressions

## 4. Documentation

- [x] 4.1 Add a `--format` section to `README.md` in English covering both flag positions, the `plain` default, example `jq` pipelines for list and result output, and that errors are JSON on stderr, and verify the wording matches the spec scenarios

## 5. Verification

- [x] 5.1 Run `swift build -c release` and verify the release build succeeds
- [x] 5.2 Run `pnpm exec openspec validate --all --no-interactive` and verify the new change and all existing specs validate cleanly
- [x] 5.3 Verify manually that default output is byte-identical to plain output before the change, that `--format json` produces parseable JSON for a list command and a create/update result, that a failing command writes JSON to stderr and exits non-zero, and that `--format bogus` reports a plain-text error naming the accepted values
