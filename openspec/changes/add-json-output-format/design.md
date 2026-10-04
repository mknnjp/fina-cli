# Design

## Context

See `proposal.md` (Why) for motivation. Current state:

- `Sources/FinaCore/Output/` already contains the full rendering seam: `OutputFormat` (a `String`-raw-value enum with `plain` and `json`), `OutputFormatter` (dispatches to `TableFormatter` or `JSONFormatter` on every render method), and the `OutputRendering` protocol. `JSONFormatter` is explicitly documented as "stub ... Not wired to commands yet".
- Commands construct their formatter indirectly: each `run()` builds a `CommandContext()` and calls `context.formatter.<render>()`. `CommandContext` already accepts an injected `formatter`, so the seam exists — only the *selected value* is missing.
- `Fina` (root command, `Sources/FinaCore/Commands/FinaCommand.swift`) declares no options and does not implement `main()`; `Sources/fina/fina.swift` calls `await Fina.main()`, so ArgumentParser's synthesized entry point runs. Today all error rendering happens inside ArgumentParser, which writes `LocalizedError.errorDescription` to stderr in plain text and exits non-zero.
- The command tree is `Fina` → `Accounts`/`Transactions` → `AccountsList` / `TransactionsList` / `TransactionsCreate` / `TransactionsUpdate`. Six commands plus the root accept no shared options today.
- Constraints: Swift 6 language mode (strict concurrency), `swift-argument-parser` 1.5+, no new dependencies, single platform-agnostic stderr write path.

## Goals / Non-Goals

**Goals:**
- One `--format` option that works at every command depth, backed by the existing `OutputFormat` enum.
- A single control point where a runtime error is rendered, so success and error output cannot drift apart.
- Keep plain mode byte-identical to today's output; keep the existing JSON schema untouched.

**Non-Goals:**
- No change to the Firefly III request/response layer, `FinaConfig`, or input validation.
- No `--pretty`, no new JSON fields, no error codes, no `--version`.
- No injection seam for command-level tests (the user chose parse-layer + formatter-layer testing); `MockURLProtocol` stays as-is.

## Decisions

### 1. `OptionGroup` repeated on every command, not a single root option
- **What:** Add `GlobalOptions: ParsableArguments` holding `@Option(name: [.customShort("f"), .customLong("format")]) var format: OutputFormat = .plain`, and attach it via `@OptionGroup` to `Fina`, `Accounts`, `AccountsList`, `Transactions`, `TransactionsList`, `TransactionsCreate`, and `TransactionsUpdate` — all seven.
- **Why:** ArgumentParser has no inherited global options. Options declared only on the root are not accepted after a subcommand name, so `fina accounts list --format json` would fail. Repeating the group on every node is the documented pattern and is what makes both invocation shapes in the spec work.
- **Alternatives considered:** (a) Root-only option — rejected, breaks the post-subcommand form. (b) Declaring `--format` individually on the four leaf commands — rejected, groups (`Accounts`, `Transactions`) would reject it and the option is defined in four places. (c) Threading the format through `CommandConfiguration.defaults` — rejected, needs a settable global.

### 2. `OutputFormat` conforms to `CaseIterable, ExpressibleByArgument`
- **What:** Add both conformances; ArgumentParser supplies the default `init?(argument:)` and derives `allValueStrings` from `CaseIterable`.
- **Why:** Zero-code parsing of `plain`/`json`, and the generated help text and the "invalid value" error automatically list the accepted values, which the spec requires. Implementing `init?(argument:)` by hand would duplicate library behavior and risk diverging from it.
- **Alternatives considered:** A `String` option plus a manual `switch` in each command — rejected, moves validation into command bodies and loses the enumerated help text.

### 3. Propagate an outer `--format` through a process-wide selection record
- **What:** `GlobalOptions.format` is `OutputFormat?` (nil = not supplied). Each command implements `validate()` and calls `globalOptions.recordDeclaredFormat()`, which stores the first non-nil value in `FormatSelection.shared`. Leaves read `globalOptions.resolvedFormat`, which records their own value (if any) and otherwise returns the recorded one.
- **Why:** ArgumentParser decodes each command separately and does not propagate option values from a parent to a child, so `fina --format json accounts list` leaves `AccountsList.format` nil. `validate()` is the documented hook invoked on each command while the parser descends, so it observes every level in root-to-leaf order. "First non-nil wins" gives the intuitive precedence: an explicit value at any level applies, and a deeper level never overwrites it with its own nil.
- **Alternatives considered:** (a) Read only the leaf's value — rejected, silently ignores the documented `fina --format json accounts list` form. (b) Pre-scan `CommandLine.arguments` — rejected, duplicates the parser and cannot see a value hidden behind a group. (c) Thread the root value through `CommandConfiguration.defaults` — rejected, needs a settable global and does not survive the leaf boundary. Trade-off: the record is process-wide state, so tests that parse must reset it; the affected suite is marked `.serialized`.

### 4. Override `Fina.main()` to own error rendering
- **What:** Implement `public static func main() async` on `Fina`: parse with `parseAsRoot()`; on parse failure delegate to `Fina.exit(withError:)` (ArgumentParser's own behavior for `--help`, `--version`, unknown flags, and invalid option values); on success run the command with the parsed format captured, and on a thrown error render it via `CommandErrorReporter` and `exit(EXIT_FAILURE)`.
- **Why:** This is the only point where both the parsed option value and the thrown error are in scope at the same time. It keeps error formatting in one place instead of repeating a `do`/`catch` in six `run()` methods, and it preserves ArgumentParser's help and usage output untouched.
- **Alternatives considered:** (a) `do`/`catch` in each `run()` — rejected, six copies of the same catch-and-report block, and the format is already available there but the duplication invites drift. (b) Override the static `exit(withError:)` — rejected, it cannot distinguish a clean `--help` exit from a real failure without re-deriving ArgumentParser's internal `CleanExit` classification. (c) Print JSON from inside `JSONFormatter` and call `exit()` there — rejected, the previous change explicitly banned `print` + `exit()` in library code.

### 5. Runtime errors honor `--format`; parse and help errors do not
- **What:** Only errors thrown from `run()` are format-aware. Parse-time failures (`--format bogus`, a missing required option) stay ArgumentParser's plain text plus usage.
- **Why:** `--help` and `--version` are reported as clean exits during parsing. To format them as JSON we would have to pre-scan `CommandLine.arguments` for `--format` before parsing, which means a second, hand-rolled parser that can disagree with the real one — and a JSON-wrapped help text is not useful to anyone. Confining format-awareness to `run()` keeps parsing authoritative in one place.
- **Alternatives considered:** (a) Pre-scan `argv` for `--format` and pass clean exits through — rejected, duplicate parsing logic for a case (help output) that should never be JSON. (b) Also wrap parse errors — rejected, same reason; a usage message is diagnostic text, not a result.

### 6. `{"error": "<message>"}` written to stderr by a dedicated reporter
- **What:** `CommandErrorReporter.message(for:)` extracts `(error as? any LocalizedError)?.errorDescription ?? error.localizedDescription`; `report(_:format:)` writes `OutputFormatter(format: format).errorLines(message)` to stderr. `OutputFormatter.errorLines` delegates to `JSONFormatter.errorJSON` in JSON mode and returns the message unchanged in plain mode.
- **Why:** All existing errors (`ConfigError`, `FireflyError`, `TransactionInputError`, `SingleSplitError`) already conform to `LocalizedError` with user-facing `errorDescription` text, so extraction is one expression and no error type needs to change. Reusing `OutputFormatter` keeps the format decision in the same dispatcher that handles success output.
- **Alternatives considered:** (a) A dedicated `ErrorFormatter` protocol — rejected, more types for a single rendering rule. (b) Adding an `error:` key per error type — rejected, spreads output concerns into error definitions. (c) Sending JSON errors to stdout — rejected, stdout is reserved for results; a consumer piping stdout would otherwise parse an error as data.

### 7. Test at the parse layer and the formatter layer, not through `run()`
- **What:** New `OutputFormatTests` covers `OutputFormat(argument:)`, `Fina.parseAsRoot([...])` for both flag positions, `OutputFormatter` JSON/error rendering, and `CommandErrorReporter.message(for:)`.
- **Why:** Commands build `CommandContext()` internally and read real credentials, so testing them end-to-end requires either a live Firefly III instance or an injection seam that the user chose not to add. Parsing and formatting are where the new logic lives; the existing `MockURLProtocol` suite already covers the HTTP layer.
- **Alternatives considered:** (a) Inject `CommandContext` into commands for mock-backed command tests — rejected for now; it is a reasonable follow-up if command-level behavior needs coverage. (b) Shell out to the built binary against a stub server — rejected, brittle and slow relative to the coverage gained.

## Risks / Trade-offs

- [Risk] Repeating `@OptionGroup` on seven commands means a future command can be added without the option, silently falling back to plain output → Mitigation: `swift run fina <new-cmd> --help` is part of verification; the option is defined once in `GlobalOptions`, so adding it is a one-line change per command.
- [Risk] `FormatSelection.shared` is process-wide state that survives between parses within one test process → Mitigation: `FormatSelection.reset()` exists for tests and the parse-dependent suite is `.serialized`; the CLI parses exactly once per process.
- [Risk] `OutputRendering` gains a method, so any future conformer breaks → Mitigation: `OutputFormatter` is the only conformer today, and the compiler points at every addition site.
- [Risk] `TransactionsList` has a test-facing `init(limit:account:)` that must now also initialize the option group → Mitigation: assign `GlobalOptions()` explicitly there; covered by compilation.
- [Risk] Overriding `Fina.main()` replaces ArgumentParser's synthesized entry point, so a mistake would affect all commands → Mitigation: the override delegates parsing failures to `Fina.exit(withError:)` unchanged and is exercised by `--help` in verification.
- [Trade-off] JSON output is compact single-line, so a human reading it directly gets one long line → Accepted; the format exists for machines, and `--pretty` is an explicit non-goal.
- [Trade-off] Errors are JSON but carry no machine-readable code, so scripts must match on message text → Accepted; adding codes means tagging every error type and is deferred (see Open Questions).

## Migration Plan

None. `plain` remains the default, no flags are removed or retyped, and existing invocations produce identical output. Rollback is a straight revert.

## Open Questions

- Whether JSON errors should later carry a stable `code` (e.g. `config_missing`) alongside the message. Deferrable: it does not change the output-format selection behavior specified here, and adding a field later is backward-compatible for consumers that ignore unknown keys.
- Whether a command-level test seam (injecting `CommandContext`) is wanted once more commands exist. Deferrable: current coverage does not depend on it.
