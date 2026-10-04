# Proposal

## Why

`fina` output is plain-text tables only, so the CLI cannot be composed with `jq`, shell scripts, or other tooling. The building blocks for machine-readable output already exist in the codebase (`OutputFormat`, `JSONFormatter`, and the `OutputFormatter` dispatch seam), but no command can reach them — `JSONFormatter` is documented as a "stub, not wired to commands yet". Wiring the existing seam into the command layer delivers scripting support without inventing new rendering logic.

## What Changes

- Add a global `--format <plain|json>` option (short `-f`) accepted by every command in the tree: `fina --format json accounts list` and `fina accounts list --format json` both work. Default stays `plain`, so existing invocations are byte-for-byte unchanged.
- Route the selected format into the existing `OutputFormatter` seam so `accounts list` and `transactions list` emit JSON, and `transactions create` / `transactions update` emit a JSON result object.
- Render runtime errors (config, API, and input-validation failures) in the selected format as a single-key JSON object on **stderr**, exiting non-zero. Plain mode keeps today's plain-text stderr messages.
- Keep `JSONFormatter`'s existing compact, single-line, key-sorted schema unchanged: `{"accounts": [...]}`, `{"transactions": [...]}`, `{"action": ..., "id": ...}`, and the new `{"error": ...}`.
- Document the option in `README.md` and cover argument parsing plus formatting with unit tests.

Non-goals: `--pretty` output, adding `currency` / `journalId` fields to JSON, machine-readable error codes, `--version`, and any change to the Firefly III request/response layer.

## Capabilities

### New Capabilities

None. JSON rendering already exists in `Output/`; this change only makes it reachable and adds a user-facing selector.

### Modified Capabilities

- `fina-cli`: The "Plain-text output" requirement changes from "always plain text, no JSON" to "plain text by default, with JSON when `--format json` is passed", and gains scenarios for JSON success output and JSON error output on stderr.

## Impact

- Affected code:
  - `Sources/FinaCore/Output/OutputFormat.swift` — `OutputFormat` gains `CaseIterable` / `ExpressibleByArgument`; `OutputFormatter` and the `OutputRendering` protocol gain an error-rendering method.
  - `Sources/FinaCore/Output/JSONFormatter.swift` — add `errorJSON(_:)`.
  - `Sources/FinaCore/Commands/Shared/GlobalOptions.swift` (new) — the shared `@OptionGroup`.
  - `Sources/FinaCore/Commands/Shared/CommandErrorReporter.swift` (new) — extracts `LocalizedError` messages and writes them to stderr in the selected format.
  - `Sources/FinaCore/Commands/Shared/CommandContext.swift` — accepts the selected format and builds `OutputFormatter(format:)`.
  - `Sources/FinaCore/Commands/FinaCommand.swift` — hosts the `OptionGroup` and overrides `main()` so runtime errors honor the selected format.
  - `Sources/FinaCore/Commands/Accounts/AccountsListCommand.swift`, `Sources/FinaCore/Commands/Transactions/*.swift` — attach the `OptionGroup` and pass the format through.
  - `Tests/finaTests/OutputFormatTests.swift` (new), `README.md`.
- Dependencies: none added. `swift-argument-parser` already provides the option and error-reporting machinery.
- Breaking changes: none. No flags are removed or retyped; `plain` remains the default and existing output is unchanged.
- Migration: none required.
