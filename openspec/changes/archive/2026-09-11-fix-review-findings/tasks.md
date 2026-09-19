## 1. Input validation (create/update)

- [x] 1.1 Add shared transaction input validator (type allowlist, YYYY-MM-DD shape, required-field and empty-update checks) and verify new unit tests for valid/invalid inputs pass
- [x] 1.2 Wire validator into `TransactionsCreate.run()` and `TransactionsUpdate.run()` so failures throw plain-text errors with no API request, and verify `swift build` succeeds

## 2. Transaction listing order

- [x] 2.1 Reorder `FireflyClient.listTransactions` to filter by account before applying local limit truncation and verify the new filter-then-limit ordering test passes
- [x] 2.2 Add combined `--account + --limit` regression test with fixture data and verify `swift test --filter MockClientTests` passes

## 3. Config loader simplification

- [x] 3.1 Refactor `ConfigLoader.load` error branching into early returns (invalid vs missing) with unchanged file-over-env precedence and verify existing `ConfigTests` still pass
- [x] 3.2 Add invalid-file-with-partial-env matrix test and verify `swift test --filter ConfigTests` passes

## 4. Table output lock-in

- [x] 4.1 Document last-column no-trailing-pad intent in `TableFormatter.alignedTable` plus missing-column fill and verify `FormatterTests` pass
- [x] 4.2 Add alignment regression test with varying-length last-column values and verify `swift test --filter FormatterTests` passes

## 5. Verification

- [x] 5.1 Run full `swift test` suite and verify all tests pass with no regressions
- [x] 5.2 Run `pnpm exec openspec validate --all --no-interactive` and verify the change validates cleanly
