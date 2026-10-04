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

### Requirement: Single-split transaction creation
The system SHALL create withdrawal, deposit, and transfer transactions with exactly one split via `fina transactions create`.

#### Scenario: Create withdrawal by account names
- **WHEN** the user provides type, date, amount, description, source name, and destination name
- **THEN** the system creates the transaction and prints its ID in plain text

#### Scenario: Create by account IDs
- **WHEN** the user provides source and destination as numeric IDs
- **THEN** the system resolves them as IDs without name lookup

#### Scenario: Reject multi-split
- **WHEN** the payload would contain more than one split
- **THEN** the CLI rejects the input with an error stating single-split only, rendered in the selected output format

#### Scenario: Reject missing required fields
- **WHEN** the user omits any of type, date, amount, description, source, or destination
- **THEN** the CLI exits non-zero with an error naming the missing fields, rendered in the selected output format, and sends no API request

#### Scenario: Reject invalid type or date
- **WHEN** the user provides a type other than withdrawal, deposit, or transfer, or a date not in `YYYY-MM-DD` shape
- **THEN** the CLI exits non-zero with an error stating the expected values, rendered in the selected output format, and sends no API request

### Requirement: Transaction update
The system SHALL update all API-updatable fields of a single-split transaction via `fina transactions update <id>`.

#### Scenario: Update description and amount
- **WHEN** the user provides a transaction ID plus updated fields
- **THEN** the system sends a PUT request with `transaction_journal_id` and prints the updated ID

#### Scenario: Reject empty update
- **WHEN** the user provides a transaction ID with no updatable fields
- **THEN** the CLI exits non-zero with an error stating at least one field is required, rendered in the selected output format, and sends no API request

#### Scenario: Reject invalid update field values
- **WHEN** the user provides an invalid type or malformed date in an update
- **THEN** the CLI exits non-zero with an error stating the expected values, rendered in the selected output format, and sends no API request

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
