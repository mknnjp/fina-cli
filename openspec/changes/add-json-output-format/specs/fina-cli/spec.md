# Spec Delta

## MODIFIED Requirements

### Requirement: Plain-text output
The system SHALL render all success and error output as human-readable plain text without JSON when no output format is requested, and the user SHALL be able to select machine-readable JSON output for both success and error output.

#### Scenario: Human-readable rows
- **WHEN** any list, create, or update command succeeds
- **THEN** output uses aligned plain-text columns or key-value lines

#### Scenario: Aligned columns
- **WHEN** a list command renders a table
- **THEN** every column including the last is padded consistently so rows align, and empty tables render headers only

#### Scenario: Default output is plain text
- **WHEN** the user runs any command without selecting an output format
- **THEN** success output is written to standard output as plain text and error output is written to standard error as plain text, matching the behavior prior to this change

#### Scenario: JSON success output on standard output
- **WHEN** the user requests JSON output and the command succeeds
- **THEN** the command writes a single valid JSON document to standard output containing the same data the plain-text output would present

#### Scenario: JSON error output on standard error
- **WHEN** the user requests JSON output and the command fails
- **THEN** the command writes a single valid JSON document to standard error containing the error message, writes nothing to standard output, and exits with a non-zero status

## ADDED Requirements

### Requirement: Output format selection
The system SHALL accept a `--format` option selecting between `plain` and `json` output, SHALL accept it at any command depth, and SHALL reject any value other than `plain` or `json`.

#### Scenario: Option accepted before a subcommand
- **WHEN** the user passes `--format json` ahead of a subcommand, as in `fina --format json accounts list`
- **THEN** the selected format applies to that subcommand's output

#### Scenario: Option accepted after a subcommand
- **WHEN** the user passes `--format json` after the deepest subcommand, as in `fina accounts list --format json`
- **THEN** the selected format applies to that subcommand's output

#### Scenario: Every command supports the option
- **WHEN** the user inspects the help text of any command in the tree, including `accounts list`, `transactions list`, `transactions create`, and `transactions update`
- **THEN** the help text lists the output format option and names `plain` and `json` as the accepted values

#### Scenario: Default value is plain
- **WHEN** the user does not pass the option
- **THEN** commands behave as if `plain` had been selected

#### Scenario: Reject unknown format value
- **WHEN** the user passes a value other than `plain` or `json`
- **THEN** the CLI exits non-zero with a plain-text message naming the accepted values and sends no API request

#### Scenario: JSON list output shape
- **WHEN** the user requests JSON output for a list command
- **THEN** the document is a single line containing one top-level key holding the result array, with one entry per row and the same field values the plain-text rows present

#### Scenario: JSON result output shape
- **WHEN** the user requests JSON output for a create or update command
- **THEN** the document contains the affected transaction identifier and the action that was performed

#### Scenario: JSON output stays machine-parseable
- **WHEN** the user requests JSON output for a successful command, including one that renders no rows
- **THEN** the output on standard output parses as a single JSON document with no trailing text, and alignment padding is absent
