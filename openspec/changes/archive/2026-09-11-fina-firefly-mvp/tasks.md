## 1. Setup

- [x] 1.1 Add swift-argument-parser dependency to Package.swift and verify `swift package resolve` succeeds
- [x] 1.2 Replace Hello World entry with `fina` root command plus `accounts` and `transactions` subcommand scaffolding and verify `swift build` succeeds and `fina --help` lists subcommands

## 2. Configuration

- [x] 2.1 Implement config loader for `~/.config/fina/config.json` with `baseURL` and `token` plus `FINA_BASE_URL`/`FINA_TOKEN` fallback and verify unit tests for valid, missing, and invalid config pass
- [x] 2.2 Enforce restrictive file permissions and actionable missing-config error and verify tests confirm 0600 mode handling and error message states expected path and required fields

## 3. API client

- [x] 3.1 Implement Codable models for Firefly JSON:API envelopes for accounts and single-split transactions with tolerant optional fields and verify decoding fixture tests pass
- [x] 3.2 Implement async URLSession API client for accounts list, transactions list, transaction create, and transaction update with Bearer auth against `<base-url>/api/v1` and verify mocked URLProtocol tests pass for all endpoints

## 4. Output formatting

- [x] 4.1 Implement plain-text table formatter for list commands and key-value lines for create/update results and verify unit tests assert aligned columns and no JSON output

## 5. Accounts commands

- [x] 5.1 Implement `fina accounts list` showing ID, name, type, currency, and balance and verify mocked client test passes and manual run prints one plain-text row per account

## 6. Transactions commands

- [x] 6.1 Implement `fina transactions list --limit N --account <id-or-name>` with reverse-chronological limit and account filtering and verify mocked tests for limit enforcement and account filtering pass
- [x] 6.2 Implement `fina transactions create` for withdrawal, deposit, and transfer single-split transactions with ID-or-name source/destination resolution and verify mocked tests confirm numeric IDs send `*_id`, names send `*_name`, and created ID is printed
- [x] 6.3 Enforce single-split-only creation in the CLI layer and verify test confirms multi-split input fails with a plain-text single-split-only error
- [x] 6.4 Implement `fina transactions update <id>` covering all API-updatable single-split fields via PUT with `transaction_journal_id` and verify mocked test asserts PUT body and updated ID output

## 7. Verification

- [x] 7.1 Run `swift test`, `swift build -c release`, and `pnpm exec openspec validate --all --no-interactive` and verify all commands succeed
