import ArgumentParser
import Foundation
import Testing

@testable import FinaCore

/// Regression tests for the crash that made `transactions create` and
/// `transactions update` unusable.
///
/// swift-argument-parser builds each command's argument set from
/// `Mirror(reflecting: type.init())`. A `ParsableCommand` initializer that
/// assigns placeholder values to `@Argument` / `@Option` properties resolves
/// those wrappers to `.value` before parsing, and the later `argumentSet(for:)`
/// call hits `fatalError("Trying to get the argument set from a resolved/parsed
/// property.")`. Any command whose initializer assigned such properties could
/// not parse at all, including `--help`.
///
/// These tests parse each command so a regression fails the test run instead of
/// crashing a user's terminal.
@Suite(.serialized) struct CommandParsingTests {
  private func parseRoot(_ arguments: [String]) throws -> any ParsableCommand {
    try Fina.parseAsRoot(arguments)
  }

  @Test func transactionsCreateParsesWithAllRequiredOptions() throws {
    let command = try parseRoot([
      "transactions", "create",
      "--type", "withdrawal",
      "--date", "2026-09-11",
      "--amount", "1500",
      "--description", "Coffee beans",
      "--source", "Main Checking",
      "--destination", "Cafe",
    ])
    let create = try #require(command as? TransactionsCreate)
    #expect(create.type == "withdrawal")
    #expect(create.date == "2026-09-11")
    #expect(create.amount == "1500")
    #expect(create.description == "Coffee beans")
    #expect(create.source == "Main Checking")
    #expect(create.destination == "Cafe")
    #expect(create.currency == nil)
  }

  @Test func transactionsCreateParsesOptionalCurrency() throws {
    let command = try parseRoot([
      "transactions", "create",
      "--type", "deposit",
      "--date", "2026-09-11",
      "--amount", "1500",
      "--description", "Salary",
      "--source", "Employer",
      "--destination", "Main Checking",
      "--currency", "JPY",
    ])
    let create = try #require(command as? TransactionsCreate)
    #expect(create.currency == "JPY")
  }

  @Test func transactionsCreateRejectsMissingRequiredOptions() {
    #expect(throws: (any Error).self) {
      try Fina.parseAsRoot(["transactions", "create", "--type", "withdrawal"])
    }
    #expect(throws: (any Error).self) {
      try Fina.parseAsRoot(["transactions", "create"])
    }
  }

  @Test func transactionsUpdateParsesPositionalIdAndFields() throws {
    let command = try parseRoot([
      "transactions", "update", "42",
      "--journal-id", "45",
      "--type", "withdrawal",
      "--date", "2026-09-10",
      "--amount", "1600",
      "--description", "Coffee beans (updated)",
      "--source", "Main Checking",
      "--destination", "Cafe",
      "--currency", "JPY",
    ])
    let update = try #require(command as? TransactionsUpdate)
    #expect(update.id == "42")
    #expect(update.journalId == "45")
    #expect(update.amount == "1600")
    #expect(update.description == "Coffee beans (updated)")
    #expect(update.currency == "JPY")
  }

  @Test func transactionsUpdateParsesIdOnly() throws {
    let command = try parseRoot(["transactions", "update", "42"])
    let update = try #require(command as? TransactionsUpdate)
    #expect(update.id == "42")
    #expect(update.amount == nil)
    #expect(update.journalId == nil)
  }

  @Test func transactionsUpdateRejectsMissingId() {
    #expect(throws: (any Error).self) {
      try Fina.parseAsRoot(["transactions", "update"])
    }
    #expect(throws: (any Error).self) {
      try Fina.parseAsRoot(["transactions", "update", "42", "--amount", "x", "--bogus", "y"])
    }
  }

  @Test func everyCommandBuildsItsArgumentSet() throws {
    // Parsing materializes `type.init()` for each command in the tree and
    // reads its argument set, which is exactly what used to crash.
    for arguments in [
      ["accounts", "list"],
      ["transactions", "list"],
      ["transactions", "update", "42"],
      [
        "transactions", "create",
        "--type", "withdrawal", "--date", "2026-09-11", "--amount", "1",
        "--description", "x", "--source", "A", "--destination", "B",
      ],
    ] {
      #expect(throws: Never.self) { try parseRoot(arguments) }
    }
  }

  @Test func requiredOptionsAreDecodedRatherThanDefaulted() throws {
    // A directly-initialized command must not expose required options:
    // reading them traps, which is why the fix removed the placeholder
    // assignments from `init()` in the first place. Parse instead.
    let create = try #require(
      try parseRoot([
        "transactions", "create",
        "--type", "withdrawal", "--date", "2026-09-11", "--amount", "1",
        "--description", "x", "--source", "A", "--destination", "B",
      ]) as? TransactionsCreate)
    #expect(create.currency == nil)

    let update = try #require(
      try parseRoot(["transactions", "update", "42"]) as? TransactionsUpdate)
    #expect(update.amount == nil)
    #expect(update.journalId == nil)
  }
}
